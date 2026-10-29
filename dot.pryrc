# frozen_string_literal: true

# vim: set fenc=utf-8 ff=unix ft=ruby ts=2 sw=2 sts=2 si et :

# refs: https://github.com/pry/pry/wiki/FAQ#wiki-awesome_print
if defined? AwesomePrint
  begin
    require 'awesome_print'
    Pry.config.print = proc { |output, value| Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output) }
    # Pry.config.print = proc { |output, value| output.puts value.ai } #ページングなし
  rescue LoadError => e
    puts 'no awesome_print :('
    puts e
  end
end

if defined?(PryByebug)
  Pry.config.commands.alias_command 'c', 'continue'
  Pry.config.commands.alias_command 's', 'step'
  Pry.config.commands.alias_command 'n', 'next'
  Pry.config.commands.alias_command 'f', 'finish'
  Pry.config.commands.alias_command 'w', 'whereami'
end

def ww
  caller.reject { |l| l.index('/gems/') }
end

# Hit Enter to repeat last command
Pry::Commands.command(/^$/, 'repeat last command') do
  last_command = Pry.history.to_a.last

  pry_instance.run_command last_command unless %w[exit disable-pry].include?(last_command)
end

Pry.config.prompt = Pry::Prompt.new(
  :yay,
  'yet another yield prompt.',
  [
    proc { |context, _, _, _|
      prompt = []
      prompt << Pry.config.prompt_name.to_s.yay_blue.to_s
      prompt << "(#{Pry.view_clip(context).to_s.yay_cyan})"
      prompt << '> '
      prompt.join
    }
  ]
)

class String
  def yay_red
    "\e[31m#{self}\e[0m"
  end

  def yay_green
    "\e[32m#{self}\e[0m"
  end

  def yay_yellow
    "\e[33m#{self}\e[0m"
  end

  def yay_blue
    "\e[34m#{self}\e[0m"
  end

  def yay_magenta
    "\e[35m#{self}\e[0m"
  end

  def yay_cyan
    "\e[36m#{self}\e[0m"
  end

  def yay_bold
    "\e[1m#{self}\e[0m"
  end

  def yay_back_blue
    "\e[44m#{self}\e[0m"
  end
end
