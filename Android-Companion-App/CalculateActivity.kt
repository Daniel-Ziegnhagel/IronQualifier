// CalculateActivity.kt
package com.iron.qualifier

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.ConnectIQ.IQConnectType
import com.garmin.android.connectiq.ConnectIQ.ConnectIQListener
import com.garmin.android.connectiq.ConnectIQ.IQMessageStatus
import com.garmin.android.connectiq.ConnectIQ.IQSdkErrorStatus
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.IQDevice.IQDeviceStatus
import com.iron.qualifier.ui.theme.IronQualifierTheme
import org.json.JSONObject
import java.io.File

// Wichtig: wir nutzen parseTime aus Calculator.kt
// sowie medianTimes, createJson, saveJsonToFile, parseXml
import com.iron.qualifier.parseTime
import com.iron.qualifier.medianTimes
import com.iron.qualifier.createJson
import com.iron.qualifier.saveJsonToFile
import com.iron.qualifier.parseXml

class CalculateActivity : ComponentActivity() {

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSIONS = 1
    }

    lateinit var connectIQ: ConnectIQ
    var iqDevice: IQDevice? = null
    var iqApp: IQApp? = null


    private val appId = "e5d9b1e7-6315-48db-9d48-898ac07451ba"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Anfordern der Berechtigungen (ab Android 12+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.BLUETOOTH_SCAN,
                        Manifest.permission.BLUETOOTH_CONNECT,
                        Manifest.permission.BLUETOOTH_ADVERTISE
                    ),
                    REQUEST_BLUETOOTH_PERMISSIONS
                )
            }
        }

        // Garmin SDK initialisieren
        initializeConnectIQ()

        setContent {
            IronQualifierTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    CalculateContent(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }

    private fun initializeConnectIQ() {
        connectIQ = ConnectIQ.getInstance(this, IQConnectType.WIRELESS)
        connectIQ.initialize(this, true, object : ConnectIQListener {
            override fun onSdkReady() {
                Log.d("GarminSDK", "SDK ist bereit")
                getConnectedDevice()
            }

            override fun onInitializeError(e: IQSdkErrorStatus?) {
                Log.e("GarminSDK", "Initialisierungsfehler: $e")
                Toast.makeText(this@CalculateActivity, "Fehler bei der SDK-Initialisierung: $e", Toast.LENGTH_LONG).show()
            }

            override fun onSdkShutDown() {
                Log.d("GarminSDK", "SDK wurde heruntergefahren")
            }
        })
    }

    private fun getConnectedDevice() {
        val devices = connectIQ.knownDevices
        if (!devices.isNullOrEmpty()) {
            // Nimm das erste gefundene Gerät.
            // Falls mehrere existieren, könntest du in Zukunft eine Auswahl bauen.
            iqDevice = devices[0]
            connectIQ.registerForDeviceEvents(iqDevice) { _, status ->
                Log.d("GarminSDK", "Gerätestatus geändert: $status")
            }
            getAppInfo()
        } else {
            Log.e("GarminSDK", "Kein verbundenes Gerät gefunden")
            Toast.makeText(this, "Kein verbundenes Garmin-Gerät gefunden.", Toast.LENGTH_LONG).show()
        }
    }

    private fun getAppInfo() {
        iqDevice?.let { device ->
            connectIQ.getApplicationInfo(appId, device, object : ConnectIQ.IQApplicationInfoListener {
                override fun onApplicationInfoReceived(app: IQApp?) {
                    iqApp = app
                    Log.d("GarminSDK", "App-Info erhalten: ${app?.displayName}")
                }

                override fun onApplicationNotInstalled(appId: String?) {
                    Log.e("GarminSDK", "App nicht installiert")
                    Toast.makeText(
                        this@CalculateActivity,
                        "Die Connect IQ App ist nicht auf dem Gerät installiert.",
                        Toast.LENGTH_LONG
                    ).show()
                }
            })
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        connectIQ.shutdown(this)
    }

    /**
     * Senden der Daten an die Garmin-Uhr
     */
    fun sendDataToGarminDevice(context: Context, fileName: String) {
        val file = File(context.filesDir, fileName)
        if (file.exists()) {
            val jsonContent = file.readText()
            // JSON parsen
            val jsonObject = JSONObject(jsonContent)
            // JSON in Map umwandeln (siehe Extensions.kt => toMap())
            val dataMap = jsonObject.toMap()

            iqDevice?.let { device ->
                iqApp?.let { app ->
                    connectIQ.sendMessage(device, app, dataMap, object : ConnectIQ.IQSendMessageListener {
                        override fun onMessageStatus(
                            device: IQDevice?,
                            app: IQApp?,
                            status: IQMessageStatus?
                        ) {
                            runOnUiThread {
                                if (status == IQMessageStatus.SUCCESS) {
                                    Log.d("GarminSDK", "Nachricht erfolgreich gesendet")
                                    Toast.makeText(context, "Daten erfolgreich übertragen.", Toast.LENGTH_LONG).show()
                                } else {
                                    Log.e("GarminSDK", "Fehler beim Senden der Nachricht: $status")
                                    Toast.makeText(context, "Fehler bei der Datenübertragung: $status", Toast.LENGTH_LONG).show()
                                }
                            }
                        }
                    })
                } ?: run {
                    Log.e("GarminSDK", "App ist nicht verfügbar")
                    Toast.makeText(context, "App-Informationen nicht verfügbar.", Toast.LENGTH_LONG).show()
                }
            } ?: run {
                Log.e("GarminSDK", "Gerät ist nicht verfügbar")
                Toast.makeText(context, "Geräteinformationen nicht verfügbar.", Toast.LENGTH_LONG).show()
            }
        } else {
            Log.e("GarminSDK", "Datei nicht gefunden: $fileName")
            Toast.makeText(context, "Die ausgewählte Datei wurde nicht gefunden.", Toast.LENGTH_LONG).show()
        }
    }
}

@Composable
fun CalculateContent(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val activity = context as? CalculateActivity

    val assetManager = context.assets
    // Sucht alle .xml Files im Asset-Ordner als "Strecken"
    val streckenList = assetManager.list("")?.filter { it.endsWith(".xml") } ?: emptyList()

    val ageGroups = listOf(
        "M18-24", "M25-29", "M30-34", "M35-39", "M40-44", "M45-49",
        "M50-54", "M55-59", "M60-64", "M65-69", "M70-74", "M75-79",
        "M80-84", "F18-24", "F25-29", "F30-34", "F35-39", "F40-44",
        "F45-49", "F50-54", "F55-59", "F60-64", "F65-69", "F70-74",
        "F75-79", "F80-84"
    )

    var selectedStrecke by remember { mutableStateOf("") }
    var selectedAgeGroup by remember { mutableStateOf("") }
    var resultsText by remember { mutableStateOf("") }
    var showTransferButton by remember { mutableStateOf(false) }
    var selectedFileName by remember { mutableStateOf("") }

    Column(modifier = modifier.padding(16.dp)) {

        Text(text = "Strecke auswählen:", style = MaterialTheme.typography.titleMedium)
        DropdownMenuField(
            items = streckenList,
            selectedItem = selectedStrecke,
            onItemSelected = { selectedStrecke = it },
            label = "Strecke"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(text = "Altersgruppe auswählen:", style = MaterialTheme.typography.titleMedium)
        DropdownMenuField(
            items = ageGroups,
            selectedItem = selectedAgeGroup,
            onItemSelected = { selectedAgeGroup = it },
            label = "Altersgruppe"
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = {
                if (selectedStrecke.isNotEmpty() && selectedAgeGroup.isNotEmpty()) {
                    val results = parseXml(context, selectedStrecke)
                    val medians = medianTimes(results, selectedAgeGroup)

                    // Auf dem Screen anzeigen:
                    resultsText = """
                        Median Zeiten:
                        Schwimmen: ${medians["swim_time"]}
                        Radfahren: ${medians["bike_time"]}
                        Laufen: ${medians["run_time"]}
                    """.trimIndent()

                    // +++ Erweiterung: Wir fügen die *seconds-Felder hinzu +++
                    // Wir konvertieren das 'medians' Map zu einem MutableMap, um zusätzliche Keys hinzuzufügen.
                    val extendedMedians = medians.toMutableMap()

                    // "swim_time" => parseTime(...) => "swim_time_seconds"
                    val swimStr = extendedMedians["swim_time"] as? String ?: "0:00:00"
                    val swimSecs = parseTime(swimStr) ?: 0
                    extendedMedians["swim_time_seconds"] = swimSecs

                    // "bike_time" => parseTime(...) => "bike_time_seconds"
                    val bikeStr = extendedMedians["bike_time"] as? String ?: "0:00:00"
                    val bikeSecs = parseTime(bikeStr) ?: 0
                    extendedMedians["bike_time_seconds"] = bikeSecs

                    // "run_time" => parseTime(...) => "run_time_seconds"
                    val runStr = extendedMedians["run_time"] as? String ?: "0:00:00"
                    val runSecs = parseTime(runStr) ?: 0
                    extendedMedians["run_time_seconds"] = runSecs

                    // JSON-Datei speichern
                    val jsonData = createJson(extendedMedians)
                    selectedFileName = "${selectedStrecke}_${selectedAgeGroup}.json"
                    saveJsonToFile(context, selectedFileName, jsonData)

                    showTransferButton = true
                } else {
                    Toast.makeText(context, "Bitte alle Felder ausfüllen.", Toast.LENGTH_SHORT).show()
                }
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = "Berechnen")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(text = resultsText)

        if (showTransferButton) {
            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    // Daten an die Garmin-Uhr senden
                    activity?.sendDataToGarminDevice(context, selectedFileName)
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = "Daten auf die Garmin Uhr übertragen")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Button, um direkt TransferActivity zu starten
        Button(
            onClick = {
                val intent = Intent(context, TransferActivity::class.java)
                context.startActivity(intent)
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = "Ergebnisse übertragen")
        }

        Spacer(modifier = Modifier.height(16.dp))

        // "Zurück"
        Button(
            onClick = {
                activity?.finish()
            },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text(text = "Zurück")
        }
    }
}
