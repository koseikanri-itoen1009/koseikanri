/*============================================================================
* ファイル名 : XxcsoVendorTypeListVORowImpl
* 概要説明   : 機器区分ポップリスト用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-03-06 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.poplist.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 機器区分用のポップリストのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVendorTypeListVORowImpl extends OAViewRowImpl 
{
  protected static final int HAZARDCLASSID = 0;


  protected static final int HAZARDCLASS = 1;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoVendorTypeListVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HazardClassId
   */
  public Number getHazardClassId()
  {
    return (Number)getAttributeInternal(HAZARDCLASSID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HazardClassId
   */
  public void setHazardClassId(Number value)
  {
    setAttributeInternal(HAZARDCLASSID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HazardClass
   */
  public String getHazardClass()
  {
    return (String)getAttributeInternal(HAZARDCLASS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HazardClass
   */
  public void setHazardClass(String value)
  {
    setAttributeInternal(HAZARDCLASS, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case HAZARDCLASSID:
        return getHazardClassId();
      case HAZARDCLASS:
        return getHazardClass();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case HAZARDCLASSID:
        setHazardClassId((Number)value);
        return;
      case HAZARDCLASS:
        setHazardClass((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}