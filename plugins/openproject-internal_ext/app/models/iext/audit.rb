# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

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
