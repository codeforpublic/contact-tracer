package com.nuuneoi.lib.contacttracer.utils;

import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.ParcelUuid;
import android.util.Log;

public class BluetoothUtils {

    public static boolean isBLEAvailable(Context context) {
        // Use this check to determine whether BLE is supported on the device. Then
        // you can selectively disable BLE-related features.
        return context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE);
    }

    public static boolean isMultipleAdvertisementSupported(BluetoothAdapter bluetoothAdapter) {
        if (bluetoothAdapter == null)
            return false;
        return bluetoothAdapter.isMultipleAdvertisementSupported();
    }

    public static ParcelUuid getServiceUUID(Context context) {
        String uuid = ResourcesUtils.getStringResource(context, "contact_tracer_bluetooth_uuid", context.getPackageName());
        if (uuid == null)
            return Constants.DefaultServiceUUID;
        return ParcelUuid.fromString(uuid);
    }

}
