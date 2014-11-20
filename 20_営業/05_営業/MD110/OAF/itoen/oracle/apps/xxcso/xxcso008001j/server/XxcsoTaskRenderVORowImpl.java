/*============================================================================
* ファイル名 : XxcsoTaskRenderVOImpl
* 概要説明   : 週次活動状況照会／属性設定用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-24 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * スケジュールリージョン属性設定用ビュークラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskRenderVORowImpl extends OAViewRowImpl 
{

  protected static final int TASKRENDER = 0;
  protected static final int NULL = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskRenderVORowImpl()
  {
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TASKRENDER:
        return getTaskRender();
      case NULL:
        return getNull();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TASKRENDER:
        setTaskRender((Boolean)value);
        return;
      case NULL:
        setNull((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskRender
   */
  public Boolean getTaskRender()
  {
    return (Boolean)getAttributeInternal(TASKRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskRender
   */
  public void setTaskRender(Boolean value)
  {
    setAttributeInternal(TASKRENDER, value);
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
}