require "json"
require "net/http"
require "uri"

class KakaoMessageService
  Result = Struct.new(:success?, :mode, :message, :response_code, keyword_init: true)

  def self.call(...)
    new.call(...)
  end

  def call(phone:, template_code:, variables:, fallback_text:)
    normalized_phone = normalize_phone(phone)
    return Result.new(success?: false, mode: mode, message: "수신자 전화번호가 없습니다") if normalized_phone.blank?

    payload = {
      phone: normalized_phone,
      template_code: template_code,
      variables: variables,
      fallback_text: fallback_text
    }

    return mock_send(payload) if mock_mode?

    real_send(payload)
  rescue StandardError => e
    Rails.logger.error("[KakaoMessageService] #{e.class}: #{e.message}")
    Result.new(success?: false, mode: mode, message: e.message)
  end

  private

  def mode
    mock_mode? ? "mock" : "api"
  end

  def mock_mode?
    ENV.fetch("KAKAO_MESSAGE_MODE", "mock") != "api"
  end

  def mock_send(payload)
    Rails.logger.info("[KakaoMessageService][MOCK] #{payload.to_json}")
    Result.new(success?: true, mode: "mock", message: "MOCK 발송 완료")
  end

  def real_send(payload)
    endpoint = ENV["KAKAO_API_ENDPOINT"].to_s
    api_key = ENV["KAKAO_API_KEY"].to_s

    raise "KAKAO_API_ENDPOINT가 설정되지 않았습니다" if endpoint.blank?
    raise "KAKAO_API_KEY가 설정되지 않았습니다" if api_key.blank?

    uri = URI.parse(endpoint)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"
    request.body = payload.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end

    ok = response.code.to_i.between?(200, 299)
    Rails.logger.info("[KakaoMessageService][API] code=#{response.code} body=#{response.body.to_s[0, 500]}")

    Result.new(
      success?: ok,
      mode: "api",
      message: ok ? "API 발송 완료" : "API 발송 실패",
      response_code: response.code.to_i
    )
  end

  def normalize_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return "" if digits.blank?

    # 010xxxxxxxx -> 8210xxxxxxxx (common provider format)
    if digits.start_with?("0")
      "82#{digits[1..]}"
    else
      digits
    end
  end
end
