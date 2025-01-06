//TransferActivity.kt
package com.iron.qualifier

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.iron.qualifier.ui.theme.IronQualifierTheme
import java.io.File

class TransferActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            IronQualifierTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    TransferContent(modifier = Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun TransferContent(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val activity = context as? CalculateActivity // Ändert Activity-Typ

    val filesDir = context.filesDir
    val jsonFiles = filesDir.listFiles()?.filter { it.name.endsWith(".json") } ?: emptyList()

    var selectedFile by remember { mutableStateOf<File?>(null) }

    Column(modifier = modifier.padding(16.dp)) {
        Text(text = "Wählen Sie eine Datei zum Übertragen aus:", style = MaterialTheme.typography.titleMedium)

        Spacer(modifier = Modifier.height(16.dp))

        if (jsonFiles.isEmpty()) {
            Text(text = "Keine berechneten Dateien gefunden.")
        } else {
            LazyColumn {
                items(jsonFiles) { file ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                selectedFile = file
                                Toast.makeText(context, "${file.name} ausgewählt", Toast.LENGTH_SHORT).show()
                            }
                            .padding(8.dp)
                    ) {
                        RadioButton(
                            selected = selectedFile == file,
                            onClick = { selectedFile = file }
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(text = file.name)
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Anzeigen der ausgewählten Datei
        selectedFile?.let { file ->
            Text(text = "Ausgewählt: ${file.name}", style = MaterialTheme.typography.bodyMedium)
        }

        Spacer(modifier = Modifier.height(16.dp))

        // "Daten jetzt übertragen" Button
        if (selectedFile != null) {
            Button(
                onClick = {
                    // Daten an die Garmin-Uhr senden
                    activity?.sendDataToGarminDevice(context, selectedFile!!.name)
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = "Daten jetzt übertragen")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // "Zurück" Button hinzufügen
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