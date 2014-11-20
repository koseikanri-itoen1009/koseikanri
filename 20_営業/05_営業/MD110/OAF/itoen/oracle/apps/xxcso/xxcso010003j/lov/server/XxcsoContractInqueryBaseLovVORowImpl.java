/*============================================================================
* �t�@�C���� : XxcsoContractInqueryBaseLovVORowImpl
* �T�v����   : �⍇���S�����_���擾LOV�r���[�s�I�u�W�F�N�g�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS����_    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.lov.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �⍇���S�����_���擾LOV�r���[�s�I�u�W�F�N�g�N���X
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractInqueryBaseLovVORowImpl extends OAViewRowImpl 
{


  protected static final int VENDORFLAG = 0;
  protected static final int VENDORID = 1;
  protected static final int INQUERYBASECODE = 2;
  protected static final int INQUERYBASENAME = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractInqueryBaseLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorFlag
   */
  public String getVendorFlag()
  {
    return (String)getAttributeInternal(VENDORFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorFlag
   */
  public void setVendorFlag(String value)
  {
    setAttributeInternal(VENDORFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VendorId
   */
  public Number getVendorId()
  {
    return (Number)getAttributeInternal(VENDORID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VendorId
   */
  public void setVendorId(Number value)
  {
    setAttributeInternal(VENDORID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InqueryBaseCode
   */
  public String getInqueryBaseCode()
  {
    return (String)getAttributeInternal(INQUERYBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InqueryBaseCode
   */
  public void setInqueryBaseCode(String value)
  {
    setAttributeInternal(INQUERYBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InqueryBaseName
   */
  public String getInqueryBaseName()
  {
    return (String)getAttributeInternal(INQUERYBASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InqueryBaseName
   */
  public void setInqueryBaseName(String value)
  {
    setAttributeInternal(INQUERYBASENAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORFLAG:
        return getVendorFlag();
      case VENDORID:
        return getVendorId();
      case INQUERYBASECODE:
        return getInqueryBaseCode();
      case INQUERYBASENAME:
        return getInqueryBaseName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VENDORFLAG:
        setVendorFlag((String)value);
        return;
      case VENDORID:
        setVendorId((Number)value);
        return;
      case INQUERYBASECODE:
        setInqueryBaseCode((String)value);
        return;
      case INQUERYBASENAME:
        setInqueryBaseName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}