/*============================================================================
* �t�@�C���� : XxcsoContractSummaryVORowImpl
* �T�v����   : �_�񏑖��׃r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS�y���    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
/*******************************************************************************
 * �_�񏑖��ׂ��o�͂��邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int SPDECISIONHEADERNUM = 0;
  protected static final int CONTRACTNUMBER = 1;
  protected static final int LASTUPDATEDATE = 2;
  protected static final int INSTALLACCOUNTNUMBER = 3;
  protected static final int INSTALLPARTYNAME = 4;
  protected static final int STATUS = 5;
  protected static final int SPDECISIONHEADERID = 6;
  protected static final int SELECTFLAG = 7;
  protected static final int CONTRACTMANAGEMENTID = 8;
  protected static final int CONTRACTFORMAT = 9;
  protected static final int COOPERATEFLAG = 10;
  protected static final int STATUSCD = 11;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionHeaderNum
   */
  public String getSpDecisionHeaderNum()
  {
    return (String)getAttributeInternal(SPDECISIONHEADERNUM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionHeaderNum
   */
  public void setSpDecisionHeaderNum(String value)
  {
    setAttributeInternal(SPDECISIONHEADERNUM, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallPartyName
   */
  public String getInstallPartyName()
  {
    return (String)getAttributeInternal(INSTALLPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallPartyName
   */
  public void setInstallPartyName(String value)
  {
    setAttributeInternal(INSTALLPARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERNUM:
        return getSpDecisionHeaderNum();
      case CONTRACTNUMBER:
        return getContractNumber();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLPARTYNAME:
        return getInstallPartyName();
      case STATUS:
        return getStatus();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SELECTFLAG:
        return getSelectFlag();
      case CONTRACTMANAGEMENTID:
        return getContractManagementId();
      case CONTRACTFORMAT:
        return getContractFormat();
      case COOPERATEFLAG:
        return getCooperateFlag();
      case STATUSCD:
        return getStatuscd();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERNUM:
        setSpDecisionHeaderNum((String)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLPARTYNAME:
        setInstallPartyName((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case CONTRACTMANAGEMENTID:
        setContractManagementId((Number)value);
        return;
      case CONTRACTFORMAT:
        setContractFormat((String)value);
        return;
      case COOPERATEFLAG:
        setCooperateFlag((String)value);
        return;
      case STATUSCD:
        setStatuscd((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractManagementId
   */
  public Number getContractManagementId()
  {
    return (Number)getAttributeInternal(CONTRACTMANAGEMENTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractManagementId
   */
  public void setContractManagementId(Number value)
  {
    setAttributeInternal(CONTRACTMANAGEMENTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ContractFormat
   */
  public String getContractFormat()
  {
    return (String)getAttributeInternal(CONTRACTFORMAT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ContractFormat
   */
  public void setContractFormat(String value)
  {
    setAttributeInternal(CONTRACTFORMAT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CooperateFlag
   */
  public String getCooperateFlag()
  {
    return (String)getAttributeInternal(COOPERATEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CooperateFlag
   */
  public void setCooperateFlag(String value)
  {
    setAttributeInternal(COOPERATEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Statuscd
   */
  public String getStatuscd()
  {
    return (String)getAttributeInternal(STATUSCD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Statuscd
   */
  public void setStatuscd(String value)
  {
    setAttributeInternal(STATUSCD, value);
  }



}