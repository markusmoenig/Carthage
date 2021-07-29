
/** Camera
 * @constructor
 * @param {Number}[60] fov - The field of view
 * @param {Number}[0.1] nearZ - Near plane
 * @param {Number}[100] farZ - Far plane
 */

CT.Camera = function(fov, nearZ, farZ) {
    if (!(this instanceof CT.Camera)) return new CT.Camera(fov, nearZ, farZ);

    this.setProjection(fov, nearZ, farZ);
};

CT.Camera.prototype.setProjection = function(fov, nearZ, farZ)
{
    if (fov === undefined) fov = 60.0;
    if (nearZ === undefined) nearZ = 0.1;
    if (farZ === undefined) farZ = 1000.0;

    /** Field of view angle, default 60 degrees
     *  @member {Number} */
    this.fov = fov;

    /** The near clipping plane
     *  @member {Number} */
    this.nearZ = nearZ;

   /** The far clipping plane
     *  @member {Number} */
    this.farZ = farZ;

   /** Aspect ratio, usually w / h, default 1.0
    *  @member {Number} */
    
    let resolution = scene.resolution;
    this.aspect = resolution.x / resolution.y;
    
    /** Projection matrix
     *  @member {CT.Math.Matrix4()} */
    this.projM = new CT.Math.Matrix4();

    /** If not null/undefined, then will use lookAt with `this.center` as center */
    this.center = new CT.Math.Vector3(0, 0, 0);
    let p = scene.camera.position;
    this.eye = new CT.Math.Vector3(p.x, p.y, p.z);
    this.up = new CT.Math.Vector3(0, 1.0, 0);
    this.lockUp = true;

    this.updateProjection();
};

/**
 * Set bounding box
 * @param {CT.Math.Vector3} min - minimum of all coordinates
 * @param {CT.Math.Vector3} max - maximum of all coordinates
 */
CT.Camera.prototype.setBoundingBox = function (min, max) {
    let center = new CT.Math.Vector3().copy(min).add(max).mul(0.5);
    let span = new CT.Math.Vector3().copy(max).sub(min);
    this.center = center;
    let factor = Math.tan(this.fov * Math.PI/180/2)*2;
    let w = span.x/factor;
    let h = span.y/factor;
    let dst = Math.max(w, h * this.aspect);

    // console.log(w, h * this.aspect, dst, factor, span.x);
    let eye = new CT.Math.Vector3().copy(this.eye).sub(center);
    eye.normalize();
    eye.mul(dst).add(center);
    this.eye = eye;
};

/** Updates the projection matrix, must be called if any member changes */

CT.Camera.prototype.updateProjection = function()
{
    this.projM.setPerspective(this.fov, this.aspect, this.nearZ, this.farZ);
};

/**
 * Activate lookAt and set lookAt parameter.
 * Will deactivate lookAt if center set to null/undefined.
 * @param {CT.Math.Vector3} center - center of view
 * @param {CT.Math.Vector3} up - up of camera, use y-axis if up is null
 * @param {CT.Math.Vector3} eye - eye location, use _position if eye is null
 * @param {Boolean} lockUp - if true, then up direction is locked.
 */

CT.Camera.prototype.setLookAt = function (center, up, eye, lockUp)
{
    if(!center){
        this.center = null;
    } else {
        this.center = center.clone();
        this.up = up ? up.clone() : new CT.Math.Vector3(0, 1, 0);
        this.up.normalize();
        this.eye = eye ? eye.clone() : this.position.clone();
        this.lockUp = lockUp;
    }
};

/**
 * Will choose whether to use SceneNode transform or lookAt transform
 * @return this camera transform.
 */

CT.Camera.prototype.getTransform = function ()
{
    let transform;
    if (this.center) {
        transform = this.getTransformLookAt();
    } else {
        //transform = VG.Render.SceneNode.prototype.getTransform.call(this);
    }

    if(this.useBoundingBox){
        let min = {x:1e32, y:1e32};
        let max = {x:-1e32, y:-1e32};
        let center = {x:0, y:0};
        for(let c0 of this.boundingBox.corners){
            let c = transform.multiplyPosition(c0);
            min.x = Math.min(c.x, min.x);
            min.y = Math.min(c.y, min.y);
            max.x = Math.max(c.x, max.x);
            max.y = Math.max(c.y, max.y);
            center.x += c.x;
            center.y += c.y;
        }
        let delta = Math.max(max.x-min.x, max.y-min.y);
        center.x /= this.boundingBox.corners.length;
        center.y /= this.boundingBox.corners.length;
        let out = new CT.Math.Matrix4().setTranslate(-center.x, -center.y, 0);
        out.concat(new CT.Math.Matrix4().setScale(2.0/delta,2.0/delta, 1.0));
        return out.concat(transform);
    } else {
        return transform;
    }
};

/**
 * Returns the world transform of this node
 * @return {CT.Math.Matrix4}
 */

CT.Camera.prototype.getTransformLookAt = function ()
{
    var m = this.__cacheM1;

    function makeLookAt(eye, center, up) {
        /**
         * A new look at matrix
         */
        var z = eye.clone();
        z.sub(center).normalize();
        var x = up.cross(z);
        var y = z.cross(x);
        m.elements[0] = x.x;
        m.elements[1] = x.y;
        m.elements[2] = x.z;
        m.elements[3] = 0;
        m.elements[4] = y.x;
        m.elements[5] = y.y;
        m.elements[6] = y.z;
        m.elements[7] = 0;
        m.elements[8] = z.x;
        m.elements[9] = z.y;
        m.elements[10] = z.z;
        m.elements[11] = 0;
        m.elements[12] = eye.x;
        m.elements[13] = eye.y;
        m.elements[14] = eye.z;
        m.elements[15] = 1;

        return m;
    }

    m = makeLookAt(this.eye, this.center, this.up);

    if (this.parent) {
        var t = this.__cacheM2;
        t.set(this.parent.getTransform());
        t.mul(m);
        return t;
    }
    return m;
};

/**
 * Rotate a vector p, around a vector v originating from o amount of alpha
 * @param {CT.Math.Vector3} p - point to rotate
 * @param {CT.Math.Vector3} o - center of rotation
 * @param {CT.Math.Vector3} v - vector to rotate around
 * @param {Number} alpha - angle to rotate (in radian)
 * @return {CT.Math.Vector3} - the rotated point
 */

CT.Camera.prototype.rotateToAPoint = function(p, o, v, alpha)
{
    var c = Math.cos(alpha);
    var s = Math.sin(alpha);
    var C = 1-c;
    var m = new CT.Math.Matrix4();

    m.elements[0] = v.x* v.x*C + c;
    m.elements[1] = v.y* v.x*C + v.z*s;
    m.elements[2] = v.z* v.x*C - v.y*s;
    m.elements[3] = 0;

    m.elements[4] = v.x* v.y*C - v.z*s;
    m.elements[5] = v.y* v.y*C + c;
    m.elements[6] = v.z* v.y*C + v.x*s;
    m.elements[7] = 0;

    m.elements[8] = v.x* v.z*C + v.y*s;
    m.elements[9] = v.y* v.z*C - v.x*s;
    m.elements[10] = v.z* v.z*C + c;
    m.elements[11] = 0;

    m.elements[12] = 0;
    m.elements[13] = 0;
    m.elements[14] = 0;
    m.elements[15] = 1;

    var P = p.clone();
    P.sub(o);
    var out = o.clone();
    out.add(m.multiplyVector3(P));
    return out;
};

/**
 * Calculate dir{x:CT.Math.Vector3, y:CT.Math.Vector3}
 * @return dir{x:CT.Math.Vector3, y:CT.Math.Vector3}
 * @private
 */

CT.Camera.prototype.calculateDirXY = function()
{
    var dir = {};
    var c_eye = this.center.clone();
    c_eye.sub(this.eye);
    dir.x = this.up.clone();
    dir.y = this.up.cross(c_eye);
    dir.y.normalize();
    return dir;
};

/**
 * Rotate as responds to mouse fractional change dx and dy
 * @param {Number} dx - mouse dx / width
 * @param {Number} dy - mouse dy / height
 */

CT.Camera.prototype.rotate = function(dx, dy)
{
    var dir = this.calculateDirXY();
    var c_up = this.center.clone();
    c_up.add(this.up);
    this.eye = this.rotateToAPoint(this.eye, this.center, dir.x, -dx * Math.PI);
    this.eye = this.rotateToAPoint(this.eye, this.center, dir.y, dy * Math.PI);
    if (!this.lockUp) {
        this.up = this.rotateToAPoint(c_up, this.center, dir.y, dy * Math.PI);
        this.up.sub(this.center);
        this.up.normalize();
    }
};

CT.Camera.prototype.zoom = function(dx, dy)
{
    this.eye.sub(this.center);
    this.eye.mul(dy + 1);
    this.eye.add(this.center);
};

/**
 * Pan
 * @param {Number} dx - mouse dx / width
 * @param {Number} dy - mouse dy / height
 */

CT.Camera.prototype.pan = function(dx, dy)
{
    var dir = this.calculateDirXY();
    var e = this.eye.clone();
    e.sub(this.center);
    var t = Math.tan(this.fov/2 * Math.PI/180);
    var len = 2 * e.length() * t;
    var pc = this.center.clone();
    dir.y.mul(dx * len * this.aspect);
    dir.x.mul(dy * len);
    this.center.add(dir.y);
    this.center.add(dir.x);
    this.eye.add(dir.y);
    this.eye.add(dir.x);
};

CT.Camera.prototype.apply = function()
{
    scene.camera.position = this.eye;
    scene.camera.lookAt = this.center;
};
