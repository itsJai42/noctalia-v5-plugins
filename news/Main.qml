import QtQuick
import Quickshell

Singleton {
  id: root
  
  property var pluginApi: null
  
  // Shared state between BarWidget and Panel
  property var newsData: []
  property string errorMessage: ""
  property bool isLoading: false
  
  // Trigger to notify BarWidget to refresh
  signal refreshRequested()
  
  function requestRefresh() {
    refreshRequested();
  }
}
