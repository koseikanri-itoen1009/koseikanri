/*============================================================================
* ファイル名 : XxcsoContractRenderVOImpl
* 概要説明   : 契約書検索／属性設定用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-26 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
/*******************************************************************************
 * 契約書検索属性設定用ビュークラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractRenderVORowImpl extends OAViewRowImpl 
{





  protected static final int CONTRACTRENDER = 0;
  protected static final int NULL = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractRenderVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTRENDER:
        return getContractRender();
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
      case CONTRACTRENDER:
        setContractRender((Boolean)value);
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
   * Gets the attribute value for the calculated attribute ContractRender
   */
  public Boolean getContractRender()
  {
    return (Boolean)getAttributeInternal(CONTRACTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractRender
   */
  public void setContractRender(Boolean value)
  {
    setAttributeInternal(CONTRACTRENDER, value);
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