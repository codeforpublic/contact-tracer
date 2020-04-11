package com.nuuneoi.lib.contacttracer.utils;

import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.ParcelUuid;

public class ResourcesUtils {

    public static int getResourceId(Context context, String variableName, String resourceName, String packageName)
    {
        try {
            return context.getResources().getIdentifier(variableName, resourceName, packageName);
        } catch (Exception e) {
            return -1;
        }
    }

    public static String getStringResource(Context context, String variableName, String packageName) {
        try {
            int resourceId = ResourcesUtils.getResourceId(context, variableName, "string", packageName);
            if (resourceId <= 0)
                return null;
            return context.getResources().getString(resourceId);
        } catch (Exception e) {
            return null;
        }
    }

}
