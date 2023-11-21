using System;

namespace McShaders
{
    using System.Collections.Generic;
    using UnityEngine;

    public sealed class ShellTextureGenerator : MonoBehaviour
    {
        #region Inspector Variables
        [Header("Necessary Materials")]
        [SerializeField] private Material _ShellTextureMaterial;

        [Header("Necessary objects")]
        [SerializeField] private GameObject _FurryObject;
        [SerializeField] private FurObject _FurPrefabs;

        [Header("Fur properties")]
        [SerializeField] private Vector3 _Size;
        [SerializeField] private int _LayersSize;
        [SerializeField] private float _Resolution;
        [SerializeField] private float _LayersSpan;
        [SerializeField] private float _FieldSize;
        [SerializeField] private float _Radius;
        [SerializeField] private float _Frequency;
        [SerializeField] private float _DisplacementStrength;
        [SerializeField] private float _SpecularStrength;
        [SerializeField] private Color _GrassColor;
        [SerializeField] private float _MovementStrength;
        [SerializeField] private float _HairMovementStrength;
        [SerializeField] private float _MovementDamping = 0.98f;
        #endregion Inspector Variables

        #region Unity Methods

        private void Start()
        {
            _ObjectBody = _FurryObject.AddComponent<Rigidbody>();
            _ObjectBody.useGravity = false;
            _CurrentLayerSize = _LayersSize;
            _CurrentFurPrefabs = _FurPrefabs;
            CleanGrassLayers(_LayersSize);
            SpawnGrassLayers(_LayersSize);
            UpdateLayersMaterials();
        }

        private void OnValidate()
        {
            //UpdateLayersMaterials();
            UpdateScale();
        }

        private void Update()
        {
            MoveSphere();
            _OppositeForce = -_ObjectBody.velocity * _MovementDamping;
            _ObjectBody.AddForce(_OppositeForce);
            UpdateLayersMaterials();
            if (CheckIfShouldRecalculateMesh())
            {
                return;
            }
            CleanGrassLayers(_CurrentLayerSize);
            SpawnGrassLayers(_LayersSize);
            _CurrentLayerSize = _LayersSize;
            _CurrentFurPrefabs = _FurPrefabs;
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
                var layer = Instantiate(_FurPrefabs.PrefabObject, _FurryObject.transform);
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
            _ShellTexturingMaterialPropertyBlock.SetVector(_FieldSizeId, _Size);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_DisplacementStrengthId, _DisplacementStrength * Cubic(heightStepSize));
            _ShellTexturingMaterialPropertyBlock.SetInt(_ObjectTypeId, (int)_FurPrefabs.ObjectType);
            _ShellTexturingMaterialPropertyBlock.SetFloat(_SpecularStrengthId, _SpecularStrength);
            _ShellTexturingMaterialPropertyBlock.SetVector(_VelocityDirectionId, _ObjectBody.velocity * _HairMovementStrength);
            layer.GetComponent<MeshRenderer>().SetPropertyBlock(_ShellTexturingMaterialPropertyBlock);
        }

        private void UpdateScale()
        {
            if (_LayersObjects == null || _LayersObjects.Count == 0)
            {
                return;
            }
            for (int i = 0; i < _LayersSize; ++i)
            {
                UpdateScaleAccordingToObjectType(_LayersObjects[i], _FurPrefabs.ObjectType);
            }
        }

        private void UpdateScaleAccordingToObjectType(GameObject layerObject, FurObjectType type)
        {
            switch (type)
            {
                case FurObjectType.Custom:
                    break;
                case FurObjectType.Quad:
                    layerObject.transform.localScale = new Vector3(_FieldSize, _FieldSize, 1.0f);
                    break;
                case FurObjectType.Sphere:
                    layerObject.transform.localScale = new Vector3(_FieldSize, _FieldSize, _FieldSize);
                    break;
                case FurObjectType.Cube:
                    layerObject.transform.localScale = new Vector3(_FieldSize, _FieldSize, _FieldSize);
                    break;
            }
        }

        private bool CheckIfShouldRecalculateMesh()
        {
            return _LayersSize == _CurrentLayerSize
                   && _FurPrefabs == _CurrentFurPrefabs;
        }

        private void UpdateLayersMaterials()
        {
            if (_LayersObjects == null || _LayersObjects.Count == 0)
            {
                return;
            }
            for (int i = 0; i < _LayersSize; ++i)
            {
                UpdateMaterial(_LayersObjects[i], _LayersSpan * i, (float)i / _LayersSize);
            }
        }

        private float Cubic(float value)
        {
            return value * value * value;
        }

        private void MoveSphere()
        {
            if (Input.GetKey(KeyCode.W))
            {
                _ObjectBody.AddForce(Vector3.forward * _MovementStrength * Time.deltaTime);
            }
            if (Input.GetKey(KeyCode.S))
            {
                _ObjectBody.AddForce(-Vector3.forward * _MovementStrength * Time.deltaTime);
            }
            if (Input.GetKey(KeyCode.A))
            {
                _ObjectBody.AddForce(-Vector3.right * _MovementStrength * Time.deltaTime);
            }
            if (Input.GetKey(KeyCode.D))
            {
                _ObjectBody.AddForce(Vector3.right * _MovementStrength * Time.deltaTime);
            }
            if (Input.GetKey(KeyCode.U))
            {
                _ObjectBody.AddForce(Vector3.up * _MovementStrength * Time.deltaTime);
            }
            if (Input.GetKey(KeyCode.J))
            {
                _ObjectBody.AddForce(-Vector3.up * _MovementStrength * Time.deltaTime);
            }
        }
        #endregion Private Methods

        #region Private Variables
        private int _CurrentLayerSize;
        private FurObject _CurrentFurPrefabs;
        private MaterialPropertyBlock _ShellTexturingMaterialPropertyBlock;

        private static readonly int _ResolutionId = Shader.PropertyToID("_Resolution");
        private static readonly int _LayerHeightId = Shader.PropertyToID("_LayerHeight");
        private static readonly int _RadiusId = Shader.PropertyToID("_Radius");
        private static readonly int _FrequencyId = Shader.PropertyToID("_Frequency");
        private static readonly int _HeightStepSizeId = Shader.PropertyToID("_HeightStepSize");
        private static readonly int _GrassColorId = Shader.PropertyToID("_GrassColor");
        private static readonly int _FieldSizeId = Shader.PropertyToID("_FieldSize");
        private static readonly int _DisplacementStrengthId = Shader.PropertyToID("_DisplacementStrength");
        private static readonly int _ObjectTypeId = Shader.PropertyToID("_ObjectType");
        private static readonly int _SpecularStrengthId = Shader.PropertyToID("_SpecularStrength");
        private static readonly int _VelocityDirectionId = Shader.PropertyToID("_VelocityDirection");

        private List<GameObject> _LayersObjects;
        private Rigidbody _ObjectBody;
        private Vector3 _OppositeForce;

        #endregion Private Variables
    }
}