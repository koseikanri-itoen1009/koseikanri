/*============================================================================
* ファイル名 : XxcsoSpDecisionBmFormatVOImpl
* 概要説明   : BMの項目サイズ設定用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-03-05 1.0   SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * BM情報のサイズを設定するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionBmFormatVORowImpl extends OAViewRowImpl 
{


  protected static final int VENDORNAME = 0;
  protected static final int VENDORNAMEALT = 1;
  protected static final int STATE = 2;
  protected static final int CITY = 3;
  protected static final int ADDRESS1 = 4;
  protected static final int ADDRESS2 = 5;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionBmFormatVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorName
   */
  public String getVendorName()
  {
    return (String)getAttributeInternal(VENDORNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorName
   */
  public void setVendorName(String value)
  {
    setAttributeInternal(VENDORNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorNameAlt
   */
  public String getVendorNameAlt()
  {
    return (String)getAttributeInternal(VENDORNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorNameAlt
   */
  public void setVendorNameAlt(String value)
  {
    setAttributeInternal(VENDORNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute State
   */
  public String getState()
  {
    return (String)getAttributeInternal(STATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute State
   */
  public void setState(String value)
  {
    setAttributeInternal(STATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute City
   */
  public String getCity()
  {
    return (String)getAttributeInternal(CITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute City
   */
  public void setCity(String value)
  {
    setAttributeInternal(CITY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address1
   */
  public String getAddress1()
  {
    return (String)getAttributeInternal(ADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address1
   */
  public void setAddress1(String value)
  {
    setAttributeInternal(ADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Address2
   */
  public String getAddress2()
  {
    return (String)getAttributeInternal(ADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Address2
   */
  public void setAddress2(String value)
  {
    setAttributeInternal(ADDRESS2, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORNAME:
        return getVendorName();
      case VENDORNAMEALT:
        return getVendorNameAlt();
      case STATE:
        return getState();
      case CITY:
        return getCity();
      case ADDRESS1:
        return getAddress1();
      case ADDRESS2:
        return getAddress2();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORNAME:
        setVendorName((String)value);
        return;
      case VENDORNAMEALT:
        setVendorNameAlt((String)value);
        return;
      case STATE:
        setState((String)value);
        return;
      case CITY:
        setCity((String)value);
        return;
      case ADDRESS1:
        setAddress1((String)value);
        return;
      case ADDRESS2:
        setAddress2((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}