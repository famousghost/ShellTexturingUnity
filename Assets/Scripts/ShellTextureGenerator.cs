namespace McShaders
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEditor.Experimental.GraphView;
    using UnityEngine;

    public sealed class ShellTextureGenerator : MonoBehaviour
    {
        #region Inspector Variables
        [Header("Necessary Materials")]
        [SerializeField] private Material _ShellTextureMaterial;

        [Header("Necessary objects")]
        [SerializeField] private GameObject _FurryObject;
        [SerializeField] private GameObject _PlanePrefab;
        [SerializeField] private List<GameObject> _LayersObjects;

        [Header("Fur properties")]
        [SerializeField] private int _LayersSize;
        [SerializeField] private float _Resolution;
        [SerializeField] private float _LayersSpan;
        [SerializeField] private float _FieldSize;
        [SerializeField] private float _Radius;
        [SerializeField] private float _Frequency;
        [SerializeField] private Color _GrassColor;
        #endregion Inspector Variables

        #region Unity Methods

        private void Start()
        {
            _CurrentLayerSize = _LayersSize;
            _CurrentLayerSpan = _LayersSpan;
            _CurrentResolution = _Resolution;
            _CurrentFieldSize = _FieldSize;
            _CurrentFrequency = _Frequency;
            _CurrentRadius = _Radius;
            CleanGrassLayers(_LayersSize);
            SpawnGrassLayers(_LayersSize);
        }

        private void Update()
        {
            if (CheckIfShouldRecalculateMesh())
            {
                return;
            }
            CleanGrassLayers(_CurrentLayerSize);
            SpawnGrassLayers(_LayersSize);
            _CurrentLayerSize = _LayersSize;
            _CurrentLayerSpan = _LayersSpan;
            _CurrentResolution = _Resolution;
            _CurrentFieldSize = _FieldSize;
            _CurrentFrequency = _Frequency;
            _CurrentRadius = _Radius;
        }
        #endregion Unity Methods

        #region Private Methods
        private void SpawnGrassLayers(int layerSize)
        {
            _LayersObjects = null;
            if (_LayersObjects == null)
            {
                _LayersObjects = new List<GameObject>();
            }
            for (int i = 0; i < layerSize; ++i)
            {
                var layer = Instantiate(_PlanePrefab, _FurryObject.transform);
                layer.transform.position += (Vector3.up * i * _LayersSpan);
                layer.transform.localScale = new Vector3(1.0f * _FieldSize, 1.0f * _FieldSize, 1.0f);
                UpdateMaterial(layer, _LayersSpan * i, (float)i / layerSize);
                _LayersObjects.Add(layer);
            }
        }

        private void CleanGrassLayers(int layerSize)
        {
            if (_LayersObjects == null || _LayersObjects.Count == 0)
            {
                return;
            }
            for (int i = 0; i < layerSize; ++i)
            {
                Destroy(_LayersObjects[i].gameObject);
            }
            _LayersObjects.Clear();
            _LayersObjects = null;
        }

        private void UpdateMaterial(GameObject layer, float layerHeight, float heightStepSize)
        {
            layer.GetComponent<MeshRenderer>().material = new Material(_ShellTextureMaterial);
            var material = layer.GetComponent<MeshRenderer>().material;
            material.SetFloat(_ResolutionId, _Resolution * _FieldSize);
            material.SetFloat(_LayerHeightId, layerHeight);
            material.SetFloat(_RadiusId, _Radius);
            material.SetFloat(_FrequencyId, _Frequency);
            material.SetFloat(_HeightStepSizeId, heightStepSize);
            material.SetColor(_GrassColorId, _GrassColor);
        }

        private bool CheckIfShouldRecalculateMesh()
        {
            return _LayersSize == _CurrentLayerSize
                   && _LayersSpan == _CurrentLayerSpan
                   && _Resolution == _CurrentResolution
                   && _FieldSize == _CurrentFieldSize
                   && _Radius == _CurrentRadius
                   && _Frequency == _CurrentFrequency
                   && _GrassColor == _CurrentGrassColor;
        }
        #endregion Private Methods

        #region Private Variables
        private int _CurrentLayerSize;
        private float _CurrentLayerSpan;
        private float _CurrentResolution;
        private float _CurrentFieldSize;
        private float _CurrentRadius;
        private float _CurrentFrequency;
        private Color _CurrentGrassColor;

        private static readonly int _ResolutionId = Shader.PropertyToID("_Resolution");
        private static readonly int _LayerHeightId = Shader.PropertyToID("_LayerHeight");
        private static readonly int _RadiusId = Shader.PropertyToID("_Radius");
        private static readonly int _FrequencyId = Shader.PropertyToID("_Frequency");
        private static readonly int _HeightStepSizeId = Shader.PropertyToID("_HeightStepSize");
        private static readonly int _GrassColorId = Shader.PropertyToID("_GrassColor");
        #endregion Private Variables
    }
}