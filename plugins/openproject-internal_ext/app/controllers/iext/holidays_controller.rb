module Iext
  class HolidaysController < BaseController
    before_action { deny_unless!(iext_admin?) }

    def index
      @holidays = Iext::Holiday.order(occurred_on: :desc).limit(400)
      @holiday = Iext::Holiday.new(occurred_on: Date.current, kind: 'holiday')
    end

    def create
      @holiday = Iext::Holiday.new(holiday_params)
      if @holiday.save
        Iext::Audit.log!(action: 'holiday.create', actor: User.current, auditable: @holiday, ip: request.remote_ip)
        flash[:notice] = I18n.t('iext.notice.created')
      else
        flash[:error] = @holiday.errors.full_messages.join(', ')
      end
      redirect_to iext_holidays_path
    end

    def destroy
      h = Iext::Holiday.find(params[:id])
      Iext::Audit.log!(action: 'holiday.delete', actor: User.current, payload: { id: h.id, name: h.name }, ip: request.remote_ip)
      h.destroy
      flash[:notice] = I18n.t('iext.notice.deleted')
      redirect_to iext_holidays_path
    end

    private

    def holiday_params
      params.require(:iext_holiday).permit(:occurred_on, :name, :kind, :user_id, :hours)
    end
  end
end
