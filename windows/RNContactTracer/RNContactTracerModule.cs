using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Contact.Tracer.RNContactTracer
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNContactTracerModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNContactTracerModule"/>.
        /// </summary>
        internal RNContactTracerModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNContactTracer";
            }
        }
    }
}
