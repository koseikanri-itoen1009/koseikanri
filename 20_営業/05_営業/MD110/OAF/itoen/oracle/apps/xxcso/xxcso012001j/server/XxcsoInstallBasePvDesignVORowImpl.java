/*============================================================================
* ファイル名 : XxcsoInstallBasePvDesignVOImpl
* 概要説明   : 物件情報汎用検索画面／ビュー指定取得ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * ビュー指定を取得するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBasePvDesignVORowImpl extends OAViewRowImpl 
{
  protected static final int SELECTVIEW = 0;


  protected static final int NULL = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBasePvDesignVORowImpl()
  {
  }

  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SELECTVIEW:
        return getSelectView();
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
      case SELECTVIEW:
        setSelectView((Number)value);
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
   * Gets the attribute value for the calculated attribute SelectView
   */
  public Number getSelectView()
  {
    return (Number)getAttributeInternal(SELECTVIEW);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectView
   */
  public void setSelectView(Number value)
  {
    setAttributeInternal(SELECTVIEW, value);
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