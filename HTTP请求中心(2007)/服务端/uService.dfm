object CenterService: TCenterService
  OldCreateOrder = False
  DisplayName = 'CenterServer'
  OnExecute = ServiceExecute
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
