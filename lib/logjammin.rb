
module Logjammin
  def logline env, *args
    tm = Time.now.to_f
    dur = tm - env[:start_time]
    tm = tm - 100 * (tm.to_i / 100)
    env.logger.debug ["%7.5f"%dur, Fiber.current.object_id, *args].map(&:to_s).map(&:chomp).join("\t")
  end
end
