{ ... }:

{
  services.fan = {
    enable = true;
    user = "pi";
    gpioPin = 18;
    pwmFrequency = 250;
    tempMin = 45.0;
    tempMax = 75.0;
    minDuty = 0.35;
  };
}
