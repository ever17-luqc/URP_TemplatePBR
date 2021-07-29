using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Text.RegularExpressions;
using UnityEngine.Rendering;
using System;
using UnityEngine.Events;

//自定义效果-Button
#region ButtonDrawer
internal class ButtonDrawer:MaterialPropertyDrawer
{
     GUILayoutOption[] buttonStyle = new GUILayoutOption[] { GUILayout.Width(90) }; 
    string singleK;
    string doubleK1;
    string doubleK2;
    string bName;
    public ButtonDrawer(string name,string Keyword)
    {
        this.singleK = Keyword;
        this.bName = name;
    }
    public ButtonDrawer(string name,string Keyword1, string Keyword2)
    {
        this.doubleK1 = Keyword1;
        this.doubleK2 = Keyword2;
        this.bName = name;
    }

    public ButtonDrawer() : this("","","") { }
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        //  base.OnGUI(position, prop, label, editor);
        float propertieValue = prop.floatValue;
        string propName = prop.name;
        string displayName = prop.displayName;

        string ButtonNameOFF = (bName == "") ? "OFF" : bName;
        string ButtonNameACTIVE = (bName == "") ? "Active" : bName;


        Material material = editor.target as Material;
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel(displayName);
        if (propertieValue==1)
        {
            if (singleK != null)
            {
                material.EnableKeyword(singleK);
            }
            else if (doubleK1 != null && doubleK2 != null)
            {
                material.EnableKeyword(doubleK1);
                material.DisableKeyword(doubleK2);
            }
            if ( GUILayout.Button(ButtonNameOFF, buttonStyle))
            {
                material.SetFloat(propName, 0);
                if(singleK!= null)
                {
                    material.DisableKeyword(singleK);
                }
                else if(doubleK1!= null && doubleK2!=null)
                {
                    material.EnableKeyword(doubleK2);
                    material.DisableKeyword(doubleK1);
                }

            }

        }

        else
        {
            if (singleK != null)
            {
                material.DisableKeyword(singleK);
            }
            else if (doubleK1 != null && doubleK2 != null)
            {
                material.EnableKeyword(doubleK2);
                material.DisableKeyword(doubleK1);
            }
            if (GUILayout.Button(ButtonNameACTIVE, buttonStyle))
            {
                material.SetFloat(propName, 1);
                if (singleK != null)
                {
                    material.EnableKeyword(singleK);
                }
                else if (doubleK1 != null && doubleK2 != null)
                {
                    material.EnableKeyword(doubleK1);
                    material.DisableKeyword(doubleK2);
                }
            }
        }
        EditorGUILayout.EndHorizontal();


    }
}
#endregion

#region SingleLineDrawer
//自定义效果-单行显示图片
internal class SingleLineDrawer : MaterialPropertyDrawer
{
    public override void OnGUI(Rect position, MaterialProperty prop, GUIContent label, MaterialEditor editor)
    {
        editor.TexturePropertySingleLine(label, prop);
    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}
#endregion
#region AdvancedFoldoutDrawer


internal class SuperFoldoutDrawer : MaterialPropertyDrawer
{
    bool showPosition;
    static bool Foldout(bool showPosition, string label)
    {
        GUIStyle style = new GUIStyle("ShurikenModuleTitle");
        style.font = new GUIStyle(EditorStyles.boldLabel).font;
        style.fontSize = new GUIStyle(EditorStyles.boldLabel).fontSize;
        style.border = new RectOffset(5, 7, 4, 4);
        style.padding = new RectOffset(5, 7, 4, 4);
        style.fixedHeight = 30;
        style.contentOffset = new Vector2(32f, -2f);
        var rect = GUILayoutUtility.GetRect(30f, 32f, style);
        GUI.Box(rect, label, style);
        var FoldRect = new Rect(rect.x - 12f, rect.y + 8f, 13f, 13f); 
        var toggleRect = new Rect(rect.x + 8f, rect.y + 8f, 13f, 13f);
        var e = Event.current;
        if (e.type == EventType.Repaint)
        {
           
            EditorStyles.foldout.Draw(FoldRect, false, false, showPosition, false);

            EditorStyles.toggle.Draw(toggleRect, false, false, showPosition, false);
            // GUI.Toggle(toggleRect, showPosition, "");

        } 
        if (e.type == EventType.MouseDown && rect.Contains(e.mousePosition))
        {
            showPosition = !showPosition;
            e.Use();
        }
        return showPosition;

       
    }

    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    {

        showPosition = Foldout(showPosition, label);
       

        prop.floatValue = Convert.ToSingle(showPosition);


    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}
#endregion


#region FoldoutDrawer
//自定义效果-折行显示图片
internal class FoldoutDrawer : MaterialPropertyDrawer
{
    bool showPosition=true;
    
    public override void OnGUI(Rect position, MaterialProperty prop, string label, MaterialEditor editor)
    { 
        showPosition = EditorGUILayout.Foldout(showPosition, label);
        prop.floatValue = Convert.ToSingle(showPosition);
    }
    public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor)
    {
        return 0;
    }
}
#endregion

public class UniversalShaderGUI : ShaderGUI
{   
    
 
    public class MaterialData
    {
        public MaterialProperty prop;
        public bool indentLevel = false;
        public bool needLineBefore = true;
        public bool indentLevelPP = false;
        public bool indentLevelSS = false;
        public int  PPNumber = 1;
        public int  SSNumber = 1;
       // public bool PassState = true;
        //public string LightModeName=null;
        //public int SurfaceType = 0;

    }
    static Dictionary<string, MaterialProperty> s_MaterialProperty = new Dictionary<string, MaterialProperty>();
    static List<MaterialData> s_List = new List<MaterialData>();
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Shader shader = (materialEditor.target as Material).shader;
        Material material = materialEditor.target as Material;
        s_List.Clear();
        s_MaterialProperty.Clear();
        for (int i = 0; i < properties.Length; i++)
        {
            var propertie = properties[i];
            s_MaterialProperty[propertie.name] = propertie;
            s_List.Add(new MaterialData() { prop = propertie, indentLevel = false , needLineBefore =false ,indentLevelPP=false,indentLevelSS=false});
            var attributes = shader.GetPropertyAttributes(i);
            foreach (var item in attributes)
            {
               
                #region 是否隐藏 控制标签
                //=======================================================是否隐藏 控制标签
                if (item.StartsWith("HideSwitch"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if(match.Success)
                    {
                        var name = match.Groups[2].Value.Trim();
                        if(s_MaterialProperty.TryGetValue(name, out var a))
                        {   //toggle对应float为0就不绘制
                            if(a.floatValue==0)
                            {
                                s_List.RemoveAt(s_List.Count - 1);
                                
                            }
                            else
                                s_List[s_List.Count - 1].indentLevel = true;
                        }
                        


                    }
                }
                if (item.StartsWith("HideWithoutTex"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if (match.Success)
                    {
                        var name = match.Groups[2].Value.Trim();
                        if (s_MaterialProperty.TryGetValue(name, out var a))
                        {   
                            if ( a.textureValue == null)
                            {
                                s_List[s_List.Count - 1].indentLevel = true;
                                

                            }
                            else
                                s_List.RemoveAt(s_List.Count - 1);
                            

                        }



                    }
                }


                //======================================================是否隐藏 控制标签
                #endregion
                //======================================================IndentLevel
                #region indentLevel
                if (item.Contains("indentLevelPP"))
                {
                    s_List[s_List.Count - 1].indentLevelPP=true;
                    int number =Convert.ToInt32( item.Substring(13));
                    s_List[s_List.Count - 1].PPNumber = number;
                }
                if (item.Contains("indentLevelSS"))
                {
                    s_List[s_List.Count - 1].indentLevelSS = true;
                    int number = Convert.ToInt32(item.Substring(13));
                    s_List[s_List.Count - 1].SSNumber = number;
                }



                #endregion
               

                #region Line 标签
                if (item==("Line"))
                {
                    s_List[s_List.Count - 1].needLineBefore = true;
                    //GUILayout.Box("", GUILayout.ExpandWidth(true), GUILayout.Height(1));
                }
                #endregion
          
                #region IsDef 控制标签
                if (item.StartsWith("IfDef"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if (match.Success)
                    {
                        var name = match.Groups[2].Value.Trim();  //name:keyword name
                        
                            if (propertie.textureValue!=null)
                            {
                            material.EnableKeyword(name);
                                
                            }
                            else
                        {
                            material.DisableKeyword(name);
                        }
                               
                    }
                }
                #endregion
                #region Foldout 控制标签
                if (item.StartsWith("if"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if (match.Success)
                    {
                        var name = match.Groups[2].Value.Trim();
                      
                        if (s_MaterialProperty.TryGetValue(name, out var a))
                        {
                            if (a.floatValue == 0) {
                                //如果有if标签，并且Foldout没有展开不进行绘制
                                s_List.RemoveAt(s_List.Count - 1); 
                                break;
                            }
                            else
                                s_List[s_List.Count - 1].indentLevel = true;
                        }
                    }
                }
                #endregion

                #region 开关Pass 控制标签
                if (item.StartsWith("Pass"))
                {
                    Match match = Regex.Match(item, @"(\w+)\s*\((.*)\)");
                    if (match.Success)
                    {
                        var name = match.Groups[2].Value.Trim();



                        //s_List[s_List.Count - 1].PassState =Convert.ToBoolean( properties[i].floatValue);
                        //s_List[s_List.Count - 1].LightModeName = name;
                        if (name != null)
                        {
                           
                            material.SetShaderPassEnabled(name, Convert.ToBoolean(properties[i].floatValue));


                        }


                    }
                }
                #endregion


                #region 透明/不透明表面 控制标签
                if (item==("SurfaceType"))
                {

                    //var name = match.Groups[2].Value.Trim();

                            s_MaterialProperty.TryGetValue(properties[i].name, out var a);
                        
                            if (a.floatValue == 0)
                            {
                                material.SetOverrideTag("RenderType", "Opaque");
                                material.renderQueue =(int) RenderQueue.Geometry;
                                material.SetFloat("_SrcBlend", (float)BlendMode.One);
                                material.SetFloat("_DstBlend", (float)BlendMode.Zero);
                                material.SetFloat("_ZWrite", 1.0f);
                        
                    }
                            else
                            {
                                material.SetOverrideTag("RenderType", "Transparent");
                                material.renderQueue = (int)RenderQueue.Transparent;
                                material.SetFloat("_SrcBlend", (float)BlendMode.SrcAlpha);
                                material.SetFloat("_DstBlend", (float)BlendMode.OneMinusSrcAlpha);
                                material.SetFloat("_ZWrite", 0); 
                    }
                               
                        
                    }
                
                #endregion

            }
        }
 
 
        /*如果不需要展开子节点像右缩进，可以直接调用base方法
         base.OnGUI(materialEditor, s_List.ToArray());*/
 
        PropertiesDefaultGUI(materialEditor, s_List);
    }
    private static int s_ControlHash = "EditorTextField".GetHashCode();
    public void PropertiesDefaultGUI(MaterialEditor materialEditor, List<MaterialData> props)
    {
        var f = materialEditor.GetType().GetField("m_InfoMessage", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
        if (f != null)
        {
            string m_InfoMessage = (string)f.GetValue(materialEditor);
            materialEditor.SetDefaultGUIWidths();
            if (m_InfoMessage != null)
            {
                EditorGUILayout.HelpBox(m_InfoMessage, MessageType.Info);
            }
            else
            {
                GUIUtility.GetControlID(s_ControlHash, FocusType.Passive, new Rect(0f, 0f, 0f, 0f));
            }
        }
        for (int i = 0; i < props.Count; i++)
        {
            MaterialProperty prop = props[i].prop;
            bool indentLevel = props[i].indentLevel;
            bool needLine = props[i].needLineBefore;
            bool indentLevelPP = props[i].indentLevelPP;
            bool indentLevelSS = props[i].indentLevelSS;
            int indentNumberPP = props[i].PPNumber;
            int indentNumberSS = props[i].SSNumber;
           // bool PassState = props[i].PassState;
            //string LightModeName = props[i].LightModeName;
            //int SurfaceType = props[i].SurfaceType;
            if ((prop.flags & (MaterialProperty.PropFlags.HideInInspector | MaterialProperty.PropFlags.PerRendererData)) == MaterialProperty.PropFlags.None)
            {
                //if(LightModeName!=null)
                //{
                //    Material material = materialEditor.target as Material;
                //    material.SetShaderPassEnabled(LightModeName, PassState);


                //}
                

                if (needLine) GUILayout.Box("", GUILayout.ExpandWidth(true), GUILayout.Height(5));
                float propertyHeight = materialEditor.GetPropertyHeight(prop, prop.displayName);
                Rect controlRect = EditorGUILayout.GetControlRect(true, propertyHeight, EditorStyles.layerMaskField);
                if(indentLevelPP) EditorGUI.indentLevel+= indentNumberPP;
                if (indentLevelSS) EditorGUI.indentLevel-= indentNumberSS;
                if (indentLevel) EditorGUI.indentLevel++;
               
                            materialEditor.ShaderProperty(controlRect, prop, prop.displayName);
                if (indentLevel) EditorGUI.indentLevel--;
               

            }
        }
        EditorGUILayout.Space();
        EditorGUILayout.Space();
        if (SupportedRenderingFeatures.active.editableMaterialRenderQueue)
        {
            materialEditor.RenderQueueField();
        }
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
    }
 
}