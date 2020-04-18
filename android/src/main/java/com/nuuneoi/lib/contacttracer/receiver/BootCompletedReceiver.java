package com.nuuneoi.lib.contacttracer.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.nuuneoi.lib.contacttracer.service.TracerService;
import com.nuuneoi.lib.contacttracer.utils.ServiceUtils;

public class BootCompletedReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        boolean serviceEnabled = TracerService.isEnabled(context);
        if (serviceEnabled) {
            ServiceUtils.startAdvertiserService(context);
        } else {
            ServiceUtils.stopAdvertiserService(context);
        }
    }

}
