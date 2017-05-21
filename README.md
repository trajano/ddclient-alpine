# ddclient-alpine
Run [ddclient](https://sourceforge.net/p/ddclient/wiki/Home/) in an alpine docker container.
This'll update your [DDNS](https://en.wikipedia.org/wiki/Dynamic_DNS) provider with your
external IP address in the event that it changes.

## Usage

### Run with docker

```bash
docker run \
       --rm \
       -ti \
       --net=host \
       -e "DDNS_USERNAME=<username>" \
       -e "DDNS_PASSWORD=<password>" \
       -e "DDNS_DOMAIN=<domain>" \
       -e "DDNS_SERVER=<server>" \
       -e "DDNS_DAEMON_OR_ONESHOT=oneshot" \
       -e "DDNS_AUTOPUBLIC_OR_INTERFACE=autopublic" \
       -e "DDNS_CHECKIP_URL=checkip.dyndns.com" \
       -e "DDNS_DAEMON_REFRESH_INTERVAL=30" \
       steasdal/ddclient-alpine
```

The `DDNS_CHECKIP_URL` and `DDNS_DAEMON_REFRESH_INTERVAL` environment variables are optional and will 
default to `checkip.dyndns.com` and `30` seconds respectively if not present.

The `DDNS_CHECKIP_URL` environment variable will be evaluated only if the
`DDNS_AUTOPUBLIC_OR_INTERFACE` variable is set to `autopublic`.

The `DDNS_DAEMON_REFRESH_INTERVAL` environment variable will be evaluated only if the
`DDNS_DAEMON_OR_ONESHOT` variable is set to `daemon`.

### Run with docker-compose

Clone this project and update all environment variable values in the `docker-compose.yml` file.
Then, from the directory that you cloned this project into, spin this image up by running the
following command:

```bash
docker-compose up -d
```

Verify that the container is running by issuing the following command and looking for a container called **ddclient**

```bash
docker-compose ps
```

Check the log output to verify that the ddclient script is actually attempting to update 
your DDNS provider by issuing the following command:

```bash
docker-compose logs --tail 200
```

Lastly, to tear the container down and toss it in the bin, try this command:

```bash
docker-compose down
```

### Deploy to a Kubernetes cluster

You're going to want to know your way around Kubernetes to attempt this.  There are plenty of tutorials and 
instructional videos out there for those willing to Google 'em.  Give yourself a day or two to get up to speed.

1. Clone this project to a location where **kubectl** can get to it (on your Kubernetes master, for instance).
2. Update all of the environment variable values in the `deployment.yaml` file.
3. Update the `username` and `password` fields in the `secret.yaml` file with [Base64 Encoded](https://www.base64encode.org/)
   versions of your DDNS username and password.
4. Create the `ddclient-secret` to hold your username and password:
    ```bash
    kubectl create -f secret.yaml
    ```
5. Create the ddclient-alpine deployment:
    ```bash
    kubectl apply -f deployment.yaml
    ```

Boom!  Just like that, you should be up and running.  Here's a sprinkling of commands that you may want to know:

* `kubectl get all` - See all of the running bits of the deployment.
* `kubectl describe pod ddclient` - Get all of the juicy deets on the pod where the **ddclient-alpine** container is running.
* `kubectl describe secret ddclient-secret` - Verify that the **ddclient-secret** secret exists in your Kubernetes environment.
* `kubectl logs --tail 200 -lapp=ddclient` - Get the last 200 lines of the ddclient log.  Very useful for verifying that the
   ddclient service actually doing its job.
* `kubectl delete -f deploymet.yaml` - Shut down the deployment and delete all the bits 'n pieces.  You'll need to run this from
   the directory where you cloned this project (e.g. the directory where your modified `deployment.yaml` file is located).
* `kubectl delete -f secret.yaml` - Delete the ddclient-secret that holds your encoded username and password.  Again, you'll
   need to run this from the directory where your modified `secret.yaml` file resides.

Check out [This document](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/) for some
insight into what's going on under the covers and, in particular, what this "secret" business is all about.

### Deploy to a Kubernetes cluster with persistent storage

So you've got your Kubernetes cluster up and running and you've deployed the `ddclient-alpine` container using the above
instructions.  Well done!  You've noticed, however, that every time the container starts up, you get a little nag message
in the log that looks like this:

`updating your.domain.name: nochg: No update required; unnecessary attempts to change to the current address are considered abusive`

Since this is Kubernetes we're talking about, we know that the lifetime of a pod may be fleeting.  The `ddclient-alpine` container
might shut down and start up all the time (in reality it probably won't but, hey, humor me for the sake of this example).  We don't
want to be accused of *abusing* our DDNS provider's gracious (and most likely free) services, do we?  Heck no we don't!  To solve
this little problem, we're going to provision some storage space for the ddclient service to keep its cache file.  This storage
space will be shared among all instances of the `ddclient-alpine` container.  The cache file itself only has a few lines of text
in it so we won't need much space at all.  We'll mount the storage space into the container as a **volumeMount**.

The instructions are going to be very similar to the above instructions with the following two exceptions:
* You'll need to create a persistent volume called **ddclient** which the deployment will create a 
  [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) from.
* You'll use the `deployment-persistent.yaml` file for the deployment instead of the `deployment.yaml` file.

You'll need to read up on [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) and figure out
how to set one up specific to your environment.  Because there are so many way to setup persistent volumes, there's no template
included in this project.  Here's an example of what a persistent volume YAML file might look like if you were running Kubernetes
on a bare metal cluster and you had some NFS volume space available to your cluster nodes:

```yaml
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: ddclient-persistent-volume
  spec:
    capacity:
      storage: 5Mi
    accessModes:
      - ReadWriteMany                        # One or more nodes will be able to attach simultaneously
    persistentVolumeReclaimPolicy: Retain
    storageClassName: ddclient               # the Persistent Volume Claim will need to have this same name
    nfs:
      path: /shares/ddclient
      server: 192.168.0.245
```
 
The important part of the above example is the **storageClassName** which is set to **ddclient**.  The `deployment-persistent.yaml`
file will attempt to create a Persistent Volume Claim against a Persistent Volume with this name when you apply it.

The above example assumes that there's an NFS server at `192.168.0.245` with a share available to all nodes in the
Kubernets cluster at `/shares/ddclient`.

Once you've got a Persistent Volume called **ddclient** in place, you're ready to rock.  Here's what you need to do:

1. Clone this project to a location where **kubectl** can get to it (on your Kubernetes master, for instance).
2. Update all of the environment variable values in the `deployment-persistent.yaml` file.
3. Update the `username` and `password` fields in the `secret.yaml` file with [Base64 Encoded](https://www.base64encode.org/)
   versions of your DDNS username and password.
4. Create the `ddclient-secret` to hold your username and password:
    ```bash
    kubectl create -f secret.yaml
    ```
5. Create the ddclient-alpine deployment with persistent storage for the ddclient cache file:
    ```bash
    kubectl apply -f deployment-persistent.yaml
    ```

Once the container is up and running, check the logs to make sure everything looks good.  Check your Persistent Volume
and verify that the container has created a file called `ddclient.cache` in it.  The following commands might come in handy:

* `kubectl get pv` - See all persistent volumes in your cluster (in the default namespace)
* `kubectl get pvc` - See all persistent volume claims in your cluster (in the default namespace)
* `kubectl delete -f deployment-persistent.yaml` - Shut down the deployment and delete everything including the
   persistent volume claim against the **ddclient** persistent volume.
* `kubectl delete -f secret.yaml` - Delete the ddclient-secret that holds your encoded username and password.

## Image
This Docker image lives on the official Docker Hub at [steasdal/ddclient-alpine](https://hub.docker.com/r/steasdal/ddclient-alpine/)