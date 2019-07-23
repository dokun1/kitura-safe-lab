# Kitura "I'm Safe" Lab

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

## Workshop Table of Contents:

1. [Getting Started](https://github.com/dokun1/kitua-safe-lab/blob/master/README.md)
2. [Setting up the Server](https://github.com/dokun1/kitua-safe-lab/blob/master/ServerSetUp.md)
3. [Setting up the Dashboard](https://github.com/dokun1/kitua-safe-lab/blob/master/DashboardSetUp.md)
4. [Setting up the iOS Client](https://github.com/dokun1/kitua-safe-lab/blob/master/iOSSetUp.md)
5. [Handling Status Reports and Disasters](https://github.com/dokun1/kitua-safe-lab/blob/master/StatusReportsAndDisasters.md)
6. [Setting up OpenAPI and REST API functionality](https://github.com/dokun1/kitua-safe-lab/blob/master/OpenAndRESTAPI.md)
7. [Build your app into a Docker image and deploy it on Kubernetes](https://github.com/dokun1/kitua-safe-lab/blob/master/DockerAndKubernetes.md)
8. **[Enable monitoring through Prometheus/Grafana](https://github.com/dokun1/kitua-safe-lab/blob/master/PrometheusAndGrafana.md)**

# Monitoring Kubernetes with Prometheus and Grafana

Kitura uses the SwiftMetrics module to provide monitoring data, covering metrics like CPU usage, memory usage and HTTP responsiveness.

SwiftMetrics provides APIs for accessing the monitoring data, as well as providing built-in integration with the Prometheus open source monitoring tool.

Whilst Prometheus can be run anywhere, it is also designed to integrate easily in a Kubernetes environment, with pre-build configurations to collect data from both Prometheus compatible applications and from Kubernetes itself.

## Installing Prometheus into Kubernetes

Installing Prometheus into Kubernetes can be done using its provided Helm chart:

```sh
helm install stable/prometheus --name prometheus --namespace prometheus
```

You can then run the following two commands in order to be able to connect to Prometheus from your browser:

```sh
export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace prometheus port-forward $POD_NAME 9090
```
You can now connect to Prometheus at the following address:

* [http://localhost:9090](http://localhost:9090)

This should show the following screen:
![prometheus-dashboard](./resources/prometheus-dashboard.png)
Prometheus will be automatically collecting data from your Kitura application, allowing you to create graphs of your data.

To build your first graph, type `os_cpu_used_ratio` into the **Expression** box and click on the **Graph** tab:

![prometheus-graph](./resources/prometheus-graph.png)


Whilst Prometheus provides the ability to build simple graphs and alerts, Grafana is commonly used to build more sophisticated dashboards.

## Installing Grafana into Kubernetes

Installing Grafana into Kubernetes can be done using its provided Helm chart:

```sh
helm install stable/grafana --set adminPassword=PASSWORD --name grafana --namespace grafana --version 1.14.3
```

You can then run the following two commands in order to be able to connect to Grafana from your browser:

```sh
export POD_NAME=$(kubectl get pods --namespace grafana -l "app=grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace grafana port-forward $POD_NAME 3000
```
You can now connect to Grafana at the following address, using `admin` and `PASSWORD` to login:

* [http://localhost:3000](http://localhost:3000)

This should show the following screen:

![grafana-home](./resources/grafana-home.png)

In order to connect Grafana to the Prometheus service, next click on **Add data source**.

This opens a panel that should be filled out with the following entries:

* Name: `Prometheus`
* Type: `Prometheus`
* URL: `http://prometheus-server.prometheus.svc.cluster.local`

![grafana-datasource](./resources/grafana-datasource.png)

Now click on **Save & Test** to check the connection and save the Data Source configuration.

Grafana now has access to the data from Prometheus.

## Installing a Kubernetes Dashboard into Grafana

The Grafana community provides a large number of pre-created dashboards which are available for download, including some which are designed to display Kubernetes data.

To install one of those dashboards, click on the **+** icon and select **Import**

![grafana-import-select](./resources/grafana-import-select.png)

In the provided panel, enter `1621` into the **Grafana.com Dashboard** field in order to import dashboard number 1621, and press **Tab**.

This then loads the information on dashboard `1621` from Grafana.com.

Set the **Prometheus** field to `Prometheus` and click **Import**.

![grafana-dashboard-import](./resources/grafana-dashboard-import.png)

This will then open the dashboard, which will automatically start populating with data about your Kubernetes cluster.

![grafana-kube-dash](./resources/grafana-kube-dash.png)

## Adding Custom Graphs

In order to extend the dashboard with your own graphs, click the **Add panel** icon on the top toolbar and select **Graph**.

![grafana-add-graph](./resources/grafana-add-graph.png)

This creates a blank graph. Select the **Panel Title** pull down menu and select **Edit**.

This opens an editor panel where you can select data that you'd like to graph.

Type `os_cpu_used_ratio` into the data box, and a graph of your applications CPU data will show on the panel.

You can create more complex queries and apply filters according to any kubernetes value. For example, the following will show all of the HTTP request durations for your specific application:

* `http_request_duration_microseconds{kubernetes_name="kiturasafeserver-service"}`

## Next Steps

You now have integrated monitoring for both your Kubernetes cluster and your deployed Kitura application.

Congratulations!  You have completed the workshop!
