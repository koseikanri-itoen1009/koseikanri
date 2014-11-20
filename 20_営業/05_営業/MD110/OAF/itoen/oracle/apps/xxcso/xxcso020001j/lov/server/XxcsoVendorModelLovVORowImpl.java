/*============================================================================
* ファイル名 : XxcsoVendorModelLovVORowImpl
* 概要説明   : 機種コードLOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 機種コードのLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoVendorModelLovVORowImpl extends OAViewRowImpl 
{


  protected static final int MAKERCODE = 0;
  protected static final int UNNUMBER = 1;
  protected static final int VENDORTYPE = 2;
  protected static final int VENDORFORM = 3;
  protected static final int SELENUMBER = 4;
  protected static final int UNNUMBERID = 5;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoVendorModelLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute MakerCode
   */
  public String getMakerCode()
  {
    return (String)getAttributeInternal(MAKERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute MakerCode
   */
  public void setMakerCode(String value)
  {
    setAttributeInternal(MAKERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnNumber
   */
  public String getUnNumber()
  {
    return (String)getAttributeInternal(UNNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumber
   */
  public void setUnNumber(String value)
  {
    setAttributeInternal(UNNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorType
   */
  public String getVendorType()
  {
    return (String)getAttributeInternal(VENDORTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorType
   */
  public void setVendorType(String value)
  {
    setAttributeInternal(VENDORTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorForm
   */
  public String getVendorForm()
  {
    return (String)getAttributeInternal(VENDORFORM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorForm
   */
  public void setVendorForm(String value)
  {
    setAttributeInternal(VENDORFORM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SeleNumber
   */
  public String getSeleNumber()
  {
    return (String)getAttributeInternal(SELENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SeleNumber
   */
  public void setSeleNumber(String value)
  {
    setAttributeInternal(SELENUMBER, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MAKERCODE:
        return getMakerCode();
      case UNNUMBER:
        return getUnNumber();
      case VENDORTYPE:
        return getVendorType();
      case VENDORFORM:
        return getVendorForm();
      case SELENUMBER:
        return getSeleNumber();
      case UNNUMBERID:
        return getUnNumberId();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case MAKERCODE:
        setMakerCode((String)value);
        return;
      case UNNUMBER:
        setUnNumber((String)value);
        return;
      case VENDORTYPE:
        setVendorType((String)value);
        return;
      case VENDORFORM:
        setVendorForm((String)value);
        return;
      case SELENUMBER:
        setSeleNumber((String)value);
        return;
      case UNNUMBERID:
        setUnNumberId((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnNumberId
   */
  public Number getUnNumberId()
  {
    return (Number)getAttributeInternal(UNNUMBERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumberId
   */
  public void setUnNumberId(Number value)
  {
    setAttributeInternal(UNNUMBERID, value);
  }
}