module Iext
  class Audit
    def self.log!(action:, actor:, auditable: nil, project: nil, payload: {}, ip: nil)
      Iext::AuditLog.create!(
        action: action,
        actor: actor,
        auditable: auditable,
        project: project || auditable.try(:project),
        payload: payload,
        ip: ip
      )
    rescue StandardError => e
      Rails.logger.error("Iext::Audit failed: #{e.message}") if defined?(Rails)
      nil
    end
  end
end
