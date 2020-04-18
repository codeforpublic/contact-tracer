package com.nuuneoi.lib.contacttracer.utils;

import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.nuuneoi.lib.contacttracer.service.TracerService;

public class ServiceUtils {

    public static void startAdvertiserService(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            context.startForegroundService(new Intent(context, TracerService.class));
        else
            context.startService(new Intent(context, TracerService.class));
    }

    public static void stopAdvertiserService(Context context) {
        context.stopService(new Intent(context, TracerService.class));
    }

}
