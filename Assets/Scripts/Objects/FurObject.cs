namespace McShaders
{
    using UnityEngine;

    public enum FurObjectType
    {
        Custom = 0,
        Quad = 1,
        Sphere = 2,
        Cube = 3
    }

    [CreateAssetMenu(fileName = "FurObjects", menuName = "McShaders/FurObject")]
    public sealed class FurObject : ScriptableObject
    {
        #region Inspector Variables
        [SerializeField] private GameObject _PrefabObject;
        [SerializeField] private FurObjectType _ObjectType;
        #endregion Inspector Variables

        #region Public Variables
        public GameObject PrefabObject
        {
            get => _PrefabObject;
            set
            {
                if (value == _PrefabObject)
                {
                    return;
                }
                _PrefabObject = value;
            }
        }

        public FurObjectType ObjectType
        {
            get => _ObjectType;
            set
            {
                if (value == _ObjectType)
                {
                    return;
                }
                _ObjectType = value;
            }
        }
        #endregion Public Variables

        #region Public Methods
        public bool Equals(FurObject p)
        {
            if (p is null)
            {
                return false;
            }

            if (Object.ReferenceEquals(this, p))
            {
                return true;
            }

            if (this.GetType() != p.GetType())
            {
                return false;
            }

            return (_PrefabObject == p._PrefabObject) && (_ObjectType == p._ObjectType);
        }

        public override int GetHashCode() => (_PrefabObject, _ObjectType).GetHashCode();

        public static bool operator ==(FurObject lhs, FurObject rhs)
        {
            if (lhs is null)
            {
                if (rhs is null)
                {
                    return true;
                }

                return false;
            }
            return lhs.Equals(rhs);
        }

        public static bool operator !=(FurObject lhs, FurObject rhs) => !(lhs == rhs);
    }
    #endregion Public Methods
}