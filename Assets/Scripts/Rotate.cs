using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    public float speed = 10f;

    void Update()
    {
        transform.localEulerAngles = new Vector3(0f, speed * Time.timeSinceLevelLoad, 0f);
    }
}
