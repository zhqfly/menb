# NOTICE: GPLv3 企业内部自用。仅内部分发，不自商用，不对外开源。
# OpenProject 12.5.8 plugin openproject-internal_ext. See /NOTICE.

# 与 OpenProject 12.5.8 官方镜像一致：Rails ~> 7.0（上游并非 Rails 6）。
# 本文件不引入新 gem，仅验证 EVM 时间占比与 CPM 工期公式。
require 'minitest/autorun'
require 'date'

class IextMathTest < Minitest::Test
  def planned_pct(as_of, start_d, due)
    return 1.0 if as_of >= due
    return 0.0 if as_of <= start_d

    span = [(due - start_d).to_f, 1.0].max
    ((as_of - start_d).to_f / span).clamp(0.0, 1.0)
  end

  def duration(start_d, due)
    return 1 unless start_d && due

    [(due - start_d).to_i + 1, 1].max
  end

  def spi(ev, pv)
    pv.to_f.positive? ? ev.to_f / pv.to_f : 0.0
  end

  def cpi(ev, ac)
    ac.to_f.positive? ? ev.to_f / ac.to_f : 0.0
  end

  def eac(bac, cpi)
    cpi.to_f.positive? ? bac.to_f / cpi.to_f : bac.to_f
  end

  def test_planned_pct_bounds
    d0 = Date.new(2026, 1, 1)
    d10 = Date.new(2026, 1, 11)
    assert_equal 0.0, planned_pct(Date.new(2025, 12, 31), d0, d10)
    assert_equal 1.0, planned_pct(Date.new(2026, 1, 11), d0, d10)
    assert_in_delta 0.5, planned_pct(Date.new(2026, 1, 6), d0, d10), 0.05
  end

  def test_evm_indices
    assert_in_delta 0.8, spi(80, 100), 0.0001
    assert_in_delta 0.8, cpi(80, 100), 0.0001
    assert_in_delta 125.0, eac(100, 0.8), 0.0001
  end

  def test_cpm_duration
    assert_equal 5, duration(Date.new(2026, 1, 1), Date.new(2026, 1, 5))
    assert_equal 1, duration(nil, nil)
  end
end
