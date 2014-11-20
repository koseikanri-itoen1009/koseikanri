/*============================================================================
* ファイル名 : XxcsoContractPubBaseLovVOImpl
* 概要説明   : 担当拠点情報取得LOVビュー行オブジェクトクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 担当拠点情報取得LOVビュー行オブジェクトクラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractPubBaseLovVORowImpl extends OAViewRowImpl 
{
  protected static final int BASECODE = 0;


  protected static final int BASENAME = 1;
  protected static final int LOCATIONADDRESS = 2;
  protected static final int BASELEADERNAME = 3;
  protected static final int BASELEADERPOSNAME = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractPubBaseLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LocationAddress
   */
  public String getLocationAddress()
  {
    return (String)getAttributeInternal(LOCATIONADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LocationAddress
   */
  public void setLocationAddress(String value)
  {
    setAttributeInternal(LOCATIONADDRESS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderName
   */
  public String getBaseLeaderName()
  {
    return (String)getAttributeInternal(BASELEADERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderName
   */
  public void setBaseLeaderName(String value)
  {
    setAttributeInternal(BASELEADERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseLeaderPosName
   */
  public String getBaseLeaderPosName()
  {
    return (String)getAttributeInternal(BASELEADERPOSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseLeaderPosName
   */
  public void setBaseLeaderPosName(String value)
  {
    setAttributeInternal(BASELEADERPOSNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case LOCATIONADDRESS:
        return getLocationAddress();
      case BASELEADERNAME:
        return getBaseLeaderName();
      case BASELEADERPOSNAME:
        return getBaseLeaderPosName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case LOCATIONADDRESS:
        setLocationAddress((String)value);
        return;
      case BASELEADERNAME:
        setBaseLeaderName((String)value);
        return;
      case BASELEADERPOSNAME:
        setBaseLeaderPosName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}