namespace McShaders
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEditor.Experimental.GraphView;
    using UnityEngine;
    using static UnityEditor.Experimental.GraphView.GraphView;

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
            CleanGrassLayers(_LayersSize);
            SpawnGrassLayers(_LayersSize);
            UpdateLayersMaterials();
        }

        private void OnValidate()
        {
            if (_LayersObjects == null || _LayersObjects.Count == 0)
            {
                return;
            }
            UpdateLayersMaterials();
        }

        private void Update()
        {
            if (CheckIfShouldRecalculateMesh())
            {
                return;
            }
            CleanGrassLayers(_CurrentLayerSize);
            SpawnGrassLayers(_LayersSize);
            UpdateLayersMaterials();
            _CurrentLayerSize = _LayersSize;
        }

        private void OnDisable()
        {
            CleanGrassLayers(_LayersSize);
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
            _ShellTexturingMaterialPropertyBlock = new MaterialPropertyBlock();

            _ShellTexturingMaterialPropertyBlock.SetFloat(_ResolutionId, _Resolution * _FieldSize);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_LayerHeightId, layerHeight);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_RadiusId, _Radius);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_FrequencyId, _Frequency);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_HeightStepSizeId, heightStepSize);
            _ShellTexturingMaterialPropertyBlock.SetColor(_GrassColorId, _GrassColor);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_FieldSizeId, _FieldSize);
            layer.GetComponent<MeshRenderer>().SetPropertyBlock(_ShellTexturingMaterialPropertyBlock);
        }

        private bool CheckIfShouldRecalculateMesh()
        {
            return _LayersSize == _CurrentLayerSize;
        }

        private void UpdateLayersMaterials()
        {
            for (int i = 0; i < _LayersObjects.Count; ++i)
            {
                UpdateMaterial(_LayersObjects[i], _LayersSpan * i, (float)i / _LayersSize);
            }
        }
        #endregion Private Methods

        #region Private Variables
        private int _CurrentLayerSize;
        private MaterialPropertyBlock _ShellTexturingMaterialPropertyBlock;

        private static readonly int _ResolutionId = Shader.PropertyToID("_Resolution");
        private static readonly int _LayerHeightId = Shader.PropertyToID("_LayerHeight");
        private static readonly int _RadiusId = Shader.PropertyToID("_Radius");
        private static readonly int _FrequencyId = Shader.PropertyToID("_Frequency");
        private static readonly int _HeightStepSizeId = Shader.PropertyToID("_HeightStepSize");
        private static readonly int _GrassColorId = Shader.PropertyToID("_GrassColor");
        private static readonly int _FieldSizeId = Shader.PropertyToID("_FieldSize");
        #endregion Private Variables
    }
}