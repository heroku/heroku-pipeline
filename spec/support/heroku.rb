def heroku(command_line)
  args = command_line.split(" ")
  command = args.shift

  Heroku::Command.load
  object, method = Heroku::Command.prepare_run(command, args)
  object.send(method)
end
