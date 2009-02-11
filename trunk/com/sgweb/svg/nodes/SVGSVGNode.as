/*
 Copyright (c) 2009 by contributors:

 * James Hight (http://labs.zavoo.com/)
 * Richard R. Masters

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

package com.sgweb.svg.nodes
{
    import com.sgweb.svg.core.SVGNode;
    import com.sgweb.svg.SVGViewer;
    import flash.geom.Matrix;

    public class SVGSVGNode extends SVGNode
    {
        protected var parentSVGRoot:SVGSVGNode = null;
        private var _pendingRenderCount:int;
        protected var firedOnLoad:Boolean = false;
        protected var scaleModeParam:String = 'svg_all';

        protected var _elementById:Object;
        protected var _referersById:Object;

        public var title:String;

        public function SVGSVGNode(svgRoot:SVGSVGNode = null, xml:XML = null) {
            if (svgRoot) {
                this.parentSVGRoot = svgRoot;
            }
            super(this, xml);
        }

        public override function set xml(value:XML):void {        
            this._elementById = new Object();    
            this._referersById = new Object();    
            if (value.@id) {
                this._elementById[value.@id] = this;
            }
            super.xml = value;

            // If this is the top SVG element, then start the render tracking process.
            if (this.parentSVGRoot == null) {
                this._pendingRenderCount = 1;
            }
        }

        override public function getAttribute(name:String, defaultValue:* = null, inherit:Boolean = true):* {

            var value:String = this._getAttribute(name);
            if (value) {
                return value;
            }

            if (ATTRIBUTES_NOT_INHERITED.indexOf(name) != -1) {
                return defaultValue;
            }

            if (inherit && (this.parent is SVGNode)) {
                return SVGNode(this.parent).getAttribute(name, defaultValue, inherit);
            }

            if ((name == 'opacity') 
                || (name == 'fill-opacity')
                || (name == 'stroke-opacity')
                || (name == 'stroke-width')) {
                return '1';
            }

            if (name == 'fill') {
                return 'black';
            }

            if (name == 'stroke') {
                return 'none';
            }

            return defaultValue;
        }

        // The following functions track the number of elements that have a redraw
        // pending. When the count reaches zero, the onLoad handler can be called.
        // 
        // The overall count starts at one to account for the top SVG element. This is done
        // in the set xml handler above.
        // Other elements increment the count when they are added. This is done
        // by an override of addChild in SVGNode.
        // Every element decrements the count when rendering is complete. This is done
        // by drawNode in SVGNode.
        public function renderPending():void {
            if (this.parentSVGRoot) {
                this.parentSVGRoot.renderPending();
            }
            else {
                this._pendingRenderCount++;
            }
        }

        public function renderFinished():void {
            if (this.parentSVGRoot) {
                this.parentSVGRoot.renderFinished();
            }
            else {
                this._pendingRenderCount--;
                if (this._pendingRenderCount == 0) {
                    if (!this.firedOnLoad) {
                        this.handleOnLoad();
                        this.firedOnLoad = true;
                    }
                }
                if (this._pendingRenderCount < 0) {
                    this.dbg("error: pendingRenderCount count negative: " + this._pendingRenderCount);
                }
            }
        }
       
        public function registerElement(id:String, node:*):void {    
            this._elementById[id] = node;
        }

        /**
         * 
         * If this object depends on another object, then we can
         * register our interest in being invalidated when the
         * dependency object is redrawn.
         * 
         **/
        public function addReference(refererId:String, referencedId:String):void {

            if (!this._referersById[referencedId]) {
                 this._referersById[referencedId]= new Array();
            }
            this._referersById[referencedId][refererId] = '';
        }

        
        public function invalidateReferers(id:String):void {
            //this.svgRoot.debug("Invalidating referers to "  + id);
            if (this._referersById[id]) {
                var referers:Array = this._referersById[id];
                for (var referer:String in referers) {
                    if (this.getElement(referer)) {
                        this.getElement(referer).invalidateDisplay();
                    }
                }
            }
        }

        /**
         * Retrieve registered node by name
         * 
         * @param id id of node to be retrieved
         * 
         * @return node registered with id
         **/
        public function getElement(id:String):* {
            if (this._elementById.hasOwnProperty(id)) {
                return this._elementById[id]; 
            }
            return null;
        }

        public function handleScript(script:String):void {
            if (this.parentSVGRoot) {
                this.parentSVGRoot.handleScript(script);
            }
            else if (this.parent is SVGViewer) {
                SVGViewer(this.parent).handleScript(script);
            }
        }

        public function handleOnLoad():void {
            if (this.parentSVGRoot) {
                this.parentSVGRoot.handleOnLoad();
            }
            else if (this.parent is SVGViewer) {
                SVGViewer(this.parent).handleOnLoad();
            }
        }

        public function debug(debugString:String):void {
            if (this.parentSVGRoot) {
                this.parentSVGRoot.debug(debugString);
            }
            else if (this.parent is SVGViewer) {
                SVGViewer(this.parent).debug(debugString);
            }
        }

    }
}