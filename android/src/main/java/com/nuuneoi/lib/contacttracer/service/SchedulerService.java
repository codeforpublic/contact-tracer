package com.nuuneoi.lib.contacttracer.service;

import android.app.job.JobParameters;
import android.app.job.JobService;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.widget.Toast;

import com.nuuneoi.lib.contacttracer.utils.ServiceUtils;

public class SchedulerService extends JobService {
    @Override
    public boolean onStartJob(JobParameters params) {
        boolean serviceEnabled = TracerService.isEnabled(this);
        if (serviceEnabled) {
            ServiceUtils.startAdvertiserService(this);
        } else {
            ServiceUtils.stopAdvertiserService(this);
        }

        return false;
    }

    @Override
    public boolean onStopJob(JobParameters params) {
        return false;
    }
}
