package com.gunes.DunyaUlkeleri.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.league")
public class LeagueProperties {

    private int winTrophies = 30;
    private int lossTrophies = 20;
    private int resetTrophies = 0;
    private int minTrophies = 0;

    public int getWinTrophies() {
        return winTrophies;
    }

    public void setWinTrophies(int winTrophies) {
        this.winTrophies = winTrophies;
    }

    public int getLossTrophies() {
        return lossTrophies;
    }

    public void setLossTrophies(int lossTrophies) {
        this.lossTrophies = lossTrophies;
    }

    public int getResetTrophies() {
        return resetTrophies;
    }

    public void setResetTrophies(int resetTrophies) {
        this.resetTrophies = resetTrophies;
    }

    public int getMinTrophies() {
        return minTrophies;
    }

    public void setMinTrophies(int minTrophies) {
        this.minTrophies = minTrophies;
    }
}

