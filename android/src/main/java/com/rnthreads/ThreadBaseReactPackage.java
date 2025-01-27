package com.rnthreads;

import com.facebook.react.ReactInstanceManager;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.devsupport.JSCHeapCapture;
import com.facebook.react.modules.appstate.AppStateModule;
import com.facebook.react.modules.core.ExceptionsManagerModule;
import com.facebook.react.modules.core.TimingModule;
import com.facebook.react.modules.debug.SourceCodeModule;
import com.facebook.react.modules.intent.IntentModule;
import com.facebook.react.modules.network.NetworkingModule;
import com.facebook.react.modules.systeminfo.AndroidInfoModule;
import com.facebook.react.modules.vibration.VibrationModule;
import com.facebook.react.modules.websocket.WebSocketModule;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ThreadBaseReactPackage implements ReactPackage {

    private final ReactInstanceManager reactInstanceManager;

    public ThreadBaseReactPackage(ReactInstanceManager reactInstanceManager) {
        this.reactInstanceManager = reactInstanceManager;
    }

    @Override
    public List<NativeModule> createNativeModules(ReactApplicationContext catalystApplicationContext) {
        return Arrays.<NativeModule>asList(new ThreadSelfModule(catalystApplicationContext));
    }

    @Override
    public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
        return new ArrayList<>(0);
    }
}
