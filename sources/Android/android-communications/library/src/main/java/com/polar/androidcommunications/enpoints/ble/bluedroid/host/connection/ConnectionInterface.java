package com.polar.androidcommunications.enpoints.ble.bluedroid.host.connection;

import com.polar.androidcommunications.enpoints.ble.bluedroid.host.BDDeviceSessionImpl;

public interface ConnectionInterface {
    void connectDevice(BDDeviceSessionImpl session);

    void disconnectDevice(BDDeviceSessionImpl session);

    void cancelDeviceConnection(BDDeviceSessionImpl session);

    void setPhy(BDDeviceSessionImpl session);

    void readPhy(BDDeviceSessionImpl session);

    boolean isPowered();

    /**
     * True when the OS still holds a GATT link to the device, e.g. one kept alive after the app
     * process that opened it died. Such a device does not advertise, so it can only be reached
     * by connecting to it directly.
     */
    boolean isConnectedAtOsLevel(BDDeviceSessionImpl session);

    boolean startServiceDiscovery(BDDeviceSessionImpl session);

    boolean setMtu(BDDeviceSessionImpl session);
}
