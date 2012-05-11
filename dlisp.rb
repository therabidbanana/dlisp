class O_o < StandardError; end
def parse(string)
  tokens = string.is_a?(Array) ? string : string.gsub(/([\(\)])/,' \1 ').split
  list = nil; t = tokens.shift
  while t != ')' && !tokens.empty?
    case t when '(';ts = parse(tokens); list ? list << ts : list = ts; else list ||= []; list << atomize(t) end
    t = tokens.shift
  end
  list
end
def atomize(i)
  ret = Integer(i);rescue;begin;ret ||= Float(i);rescue;ret ||= i.to_sym; end
end
def call(x, env=new_env)
  return env[x] if x.is_a?(Symbol)
  return x unless x.is_a?(Array)
  (atom,b,c) = x;
  case atom when :quote; b; when :define; env[b] = call(c, env); nil  # simple return, simple define - calling before storing
  when :set!; env[b, call(c,env)]; nil # Set only if b defined, always nil return
  when :begin;  (a, *d) = x; d.map{|exp| call(exp, env) }.last # (a, *b) = x for (cdr x), then map
  when :lambda; (->(*args){call(c, new_env(b, args, env)) })
  when :if; alt = x.last; call(call(b, env) ? c : alt, env) # define last, eval either c or last depending on eval of b
  else
    (n, *d) = x.map{|exp| call(exp, env)};
    n[*d] # Pull out initial procedure name and then call it with list of args evaled
  end
end
class Env
  attr_accessor :parent, :data
  def initialize(keys, vals, outer_env = nil)
    outer_env ||= global_env
    @parent = outer_env; @data = {}
    keys.each_with_index{|d, i| @data[d] = vals[i]  }
  end
  def [](k, set_if = nil)
    if set_if
      @data.has_key?(k) ? self[k]=set_if : (@parent[k, set_if] if @parent)
    else
      @data.has_key?(k) ? @data[k] : (@parent[k] if @parent)
    end
  end

  def []=(k,v); @data[k] = v; end
end
def new_env(*args); (a,b,c)=args; a||=[]; b||=[]; Env.new(a,b,c); end
def global_env
  glob = {
    :+ => ->(a,b){a+b},
    :> => ->(a,b){a>b},
    :< => ->(a,b){a<b},
    :* => ->(a,b){a*b}
  }
  Env.new(glob.keys,glob.values,{})
end

warn call(parse("(begin (define sexy (lambda (r) (* 3.141592653 (* r r))))(if (> 1 0) (sexy 3) (quote (0))))")).inspect
