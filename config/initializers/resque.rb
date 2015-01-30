
Resque.redis = "#{Settings.redis.host}:#{Settings.redis.port}"
Resque.redis.namespace = Settings.redis.namespace

Resque.redis.flushdb if Rails.env == 'test'
