
$redis = Redis.new(Settings.redis.to_hash)
$redis_ns = Redis::Namespace.new(Settings.redis.namespace, redis: $redis)

$redis.flushdb if Rails.env == 'test'
