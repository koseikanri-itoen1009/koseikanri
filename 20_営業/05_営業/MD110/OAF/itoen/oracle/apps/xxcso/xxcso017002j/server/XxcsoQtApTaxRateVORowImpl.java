/*============================================================================
* ファイル名 : XxcsoQtApTaxRateVOImpl
* 概要説明   : 仮払税率取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS桐生和幸  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * 仮払税率取得のビュー行クラスです。
 * @author  SCS桐生和幸
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVORowImpl extends OAViewRowImpl 
{
  protected static final int APTAXRATE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApTaxRate
   */
  public Number getApTaxRate()
  {
    return (Number)getAttributeInternal(APTAXRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApTaxRate
   */
  public void setApTaxRate(Number value)
  {
    setAttributeInternal(APTAXRATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        return getApTaxRate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        setApTaxRate((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}