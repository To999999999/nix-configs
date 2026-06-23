{ config, lib, pkgs, ... }:

let
  cfg = config.services.fan;
  fanPackage = cfg.package;

  defaultConfig = {
    TEMP_MIN = cfg.tempMin;
    TEMP_MAX = cfg.tempMax;
    MIN_DUTY = cfg.minDuty;
    PWM_PIN = cfg.gpioPin;
    PWM_FREQUENCY = cfg.pwmFrequency;
    CHECK_INTERVAL = cfg.checkInterval;
    MIN_CHANGE_INTERVAL = cfg.minChangeInterval;
    MODE = "auto";
    MANUAL_DUTY = 0;
  };
in
{
  options.services.fan = {
    enable = lib.mkEnableOption "PWM fan controller";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fan;
      description = "Fan controller package.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pi";
    };

    gpioPin = lib.mkOption {
      type = lib.types.int;
      default = 18;
    };

    pwmFrequency = lib.mkOption {
      type = lib.types.int;
      default = 250;
    };

    tempMin = lib.mkOption {
      type = lib.types.float;
      default = 35.0;
    };

    tempMax = lib.mkOption {
      type = lib.types.float;
      default = 70.0;
    };

    minDuty = lib.mkOption {
      type = lib.types.float;
      default = 0.40;
    };

    checkInterval = lib.mkOption {
      type = lib.types.float;
      default = 5.0;
    };

    minChangeInterval = lib.mkOption {
      type = lib.types.float;
      default = 60.0;
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.gpio = {};
    users.users.${cfg.user}.extraGroups = [ "gpio" ];

    services.udev.extraRules = ''
      KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
      KERNEL=="gpiomem", GROUP="gpio", MODE="0660"
    '';

    environment.systemPackages = [ fanPackage ];

    environment.etc."fan/default-config.json".text =
      builtins.toJSON defaultConfig;

    systemd.tmpfiles.rules = [
      "d /var/lib/fan 0750 ${cfg.user} gpio - -"
    ];

    systemd.services.fan-init-config = {
      description = "Initialize fan config";
      wantedBy = [ "multi-user.target" ];
      before = [ "fan.service" ];

      serviceConfig.Type = "oneshot";

      script = ''
        install -d -o ${cfg.user} -g gpio -m 0750 /var/lib/fan

        if [ ! -e /var/lib/fan/config.json ]; then
          cp /etc/fan/default-config.json /var/lib/fan/config.json
          chown ${cfg.user}:gpio /var/lib/fan/config.json
          chmod 0640 /var/lib/fan/config.json
        fi
      '';
    };

    systemd.services.fan = {
      description = "PWM Fan Controller";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "gpio";
	WorkingDirectory = "/var/lib/fan";
        ExecStart = "${fanPackage}/bin/fan --daemon";
        Restart = "always";
        StateDirectory = "fan";
      };
    };
  };
}
