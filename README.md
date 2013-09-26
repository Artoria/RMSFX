Insert before any call or require from RMSFX
```ruby
  $:.unshift "C:/RMSFX"
  ENV['path'] = "C:/RMSFX/bin;" + ENV['path']
```

if you are using RMVX, you'll need to patch Object#require:
```ruby
class Object
  def require *a
     Kernel.require *a
  end
end
```
