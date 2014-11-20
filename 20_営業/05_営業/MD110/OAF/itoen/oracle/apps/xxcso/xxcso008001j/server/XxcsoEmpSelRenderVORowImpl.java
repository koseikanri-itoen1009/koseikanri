/*============================================================================
* ファイル名 : XxcsoEmpSelRenderVORowImpl
* 概要説明   : 週次活動状況照会／属性設定用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-27 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 担当者選択リージョン属性設定用ビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpSelRenderVORowImpl extends OAViewRowImpl 
{

  protected static final int NULL = 0;


  protected static final int EMPSELRENDER = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpSelRenderVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Null
   */
  public String getNull()
  {
    return (String)getAttributeInternal(NULL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Null
   */
  public void setNull(String value)
  {
    setAttributeInternal(NULL, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case NULL:
        return getNull();
      case EMPSELRENDER:
        return getEmpSelRender();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case NULL:
        setNull((String)value);
        return;
      case EMPSELRENDER:
        setEmpSelRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmpSelRender
   */
  public Boolean getEmpSelRender()
  {
    return (Boolean)getAttributeInternal(EMPSELRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmpSelRender
   */
  public void setEmpSelRender(Boolean value)
  {
    setAttributeInternal(EMPSELRENDER, value);
  }



}