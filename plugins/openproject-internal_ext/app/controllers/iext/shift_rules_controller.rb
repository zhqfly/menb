module Iext
  class ShiftRulesController < BaseController
    before_action { deny_unless!(iext_admin?) }

    def index
      @rules = Iext::ShiftRule.includes(:user).order(:user_id, :weekday)
      @rule = Iext::ShiftRule.new(capacity_hours: 8, weekday: 1)
      @users = User.where(status: 1).order(:firstname)
    end

    def create
      @rule = Iext::ShiftRule.new(rule_params)
      if @rule.save
        Iext::Audit.log!(action: 'shift.create', actor: User.current, auditable: @rule, ip: request.remote_ip)
        flash[:notice] = I18n.t('iext.notice.created')
      else
        flash[:error] = @rule.errors.full_messages.join(', ')
      end
      redirect_to iext_shift_rules_path
    end

    def destroy
      r = Iext::ShiftRule.find(params[:id])
      Iext::Audit.log!(action: 'shift.delete', actor: User.current, payload: { id: r.id }, ip: request.remote_ip)
      r.destroy
      redirect_to iext_shift_rules_path
    end

    private

    def rule_params
      params.require(:iext_shift_rule).permit(:user_id, :weekday, :capacity_hours, :shift_name, :active)
    end
  end
end
