/*============================================================================
* �t�@�C���� : XxcsoValidateAcctRsrsVORowImpl
* �T�v����   : �K��E����v���ʁ@�o���f�[�V�����`�F�b�N�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS�p�M�F�@  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * �K��E����v���ʁ@�o���f�[�V�����`�F�b�N�r���[�s�N���X
 * @author  SCS�p�M�F
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoValidateAcctRsrsVORowImpl extends OAViewRowImpl 
{


  protected static final int ACCOUNTNUMBER = 0;
  protected static final int PARTYID = 1;
  protected static final int VISTTARGETDIV = 2;
  protected static final int STARTDATEACTIVE = 3;
  protected static final int ENDDATEACTIVE = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoValidateAcctRsrsVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyId
   */
  public Number getPartyId()
  {
    return (Number)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyId
   */
  public void setPartyId(Number value)
  {
    setAttributeInternal(PARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VistTargetDiv
   */
  public String getVistTargetDiv()
  {
    return (String)getAttributeInternal(VISTTARGETDIV);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VistTargetDiv
   */
  public void setVistTargetDiv(String value)
  {
    setAttributeInternal(VISTTARGETDIV, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case PARTYID:
        return getPartyId();
      case VISTTARGETDIV:
        return getVistTargetDiv();
      case STARTDATEACTIVE:
        return getStartDateActive();
      case ENDDATEACTIVE:
        return getEndDateActive();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case PARTYID:
        setPartyId((Number)value);
        return;
      case VISTTARGETDIV:
        setVistTargetDiv((String)value);
        return;
      case STARTDATEACTIVE:
        setStartDateActive((Date)value);
        return;
      case ENDDATEACTIVE:
        setEndDateActive((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StartDateActive
   */
  public Date getStartDateActive()
  {
    return (Date)getAttributeInternal(STARTDATEACTIVE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StartDateActive
   */
  public void setStartDateActive(Date value)
  {
    setAttributeInternal(STARTDATEACTIVE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EndDateActive
   */
  public Date getEndDateActive()
  {
    return (Date)getAttributeInternal(ENDDATEACTIVE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EndDateActive
   */
  public void setEndDateActive(Date value)
  {
    setAttributeInternal(ENDDATEACTIVE, value);
  }
}