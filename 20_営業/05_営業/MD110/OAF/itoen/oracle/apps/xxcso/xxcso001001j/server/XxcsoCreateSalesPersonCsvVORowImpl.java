/*============================================================================
* ファイル名 : XxcsoCreateSalesPersonCsvVORowImp1
* 概要説明   : 売上計画出力／営業員別計画CSV出力用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-11 1.0  SCS丸山美緒　  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso001001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 売上計画出力　営業員別計画CSV出力用ビュー行クラス
 * @author  SCS丸山美緒
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCreateSalesPersonCsvVORowImpl extends OAViewRowImpl 
{


  protected static final int DATAKINDFLAG = 0;
  protected static final int BUSINESSYEAR = 1;
  protected static final int YEARMONTH = 2;
  protected static final int SLSPRSNXSTSF = 3;
  protected static final int BASECODE = 4;
  protected static final int BASENAME = 5;
  protected static final int BSCSLSNEWSERVAMT = 6;
  protected static final int BSCSLSNEXTSERVAMT = 7;
  protected static final int BSCSLSEXISTSERVAMT = 8;
  protected static final int BSCDISCOUNT = 9;
  protected static final int BSCTOTALSLSAMT = 10;
  protected static final int DEFCNTTOTAL = 11;
  protected static final int TARGETDISCOUNTAMT = 12;
  protected static final int GROUPNUMBER = 13;
  protected static final int GROUPLEADERFLAG = 14;
  protected static final int GROUPLEADERNAME = 15;
  protected static final int GROUPGRADE = 16;
  protected static final int EMPLOYEENUMBER = 17;
  protected static final int EMPLOYEENAME = 18;
  protected static final int JOBLANK = 19;
  protected static final int PRIRSLTVDNEWSERVAMT = 20;
  protected static final int PRIRSLTVDNEXTSERVAMT = 21;
  protected static final int PRIRSLTVDEXISTSERVAMT = 22;
  protected static final int PRIRSLTNEWSERVAMT = 23;
  protected static final int PRIRSLTNEXTSERVAMT = 24;
  protected static final int PRIRSLTEXISTSERVAMT = 25;
  protected static final int BSCSLSVDNEWSERVAMT = 26;
  protected static final int BSCSLSVDNEXTSERVAMT = 27;
  protected static final int BSCSLSVDEXISTSERVAMT = 28;
  protected static final int BSCSLSNEWSERVAMT1 = 29;
  protected static final int BSCSLSNEXTSERVAMT1 = 30;
  protected static final int BSCSLSPRSNTOTALAMT = 31;
  protected static final int TGTSALESVDNEWSERVAMT = 32;
  protected static final int TGTSALESVDNEXTSERVAMT = 33;
  protected static final int TGTSALESVDEXISTSERVAMT = 34;
  protected static final int TGTSALESNEWSERVAMT = 35;
  protected static final int TGTSALESNEXTSERVAMT = 36;
  protected static final int TGTSALESPRSNTOTALAMT = 37;
  protected static final int RSLTVDNEWSERVAMT = 38;
  protected static final int RSLTVDEXISTSERVAMT = 39;
  protected static final int RSLTVDTOTALAMT = 40;
  protected static final int RSLTNEWSERVAMT = 41;
  protected static final int RSLTNEXTSERVAMT = 42;
  protected static final int RSLTPRSNTOTALAMT = 43;
  protected static final int VISVDTOTALAMT = 44;
  protected static final int VISPRSNTOTALAMT = 45;
  protected static final int SLSPLNEFFECTIVEFLAG = 46;
  protected static final int MAX_ITEM_ID = SLSPLNEFFECTIVEFLAG;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCreateSalesPersonCsvVORowImpl()
  {
  }

  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DATAKINDFLAG:
        return getDataKindFlag();
      case BUSINESSYEAR:
        return getBusinessYear();
      case YEARMONTH:
        return getYearMonth();
      case SLSPRSNXSTSF:
        return getSlsprsnXstsF();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case BSCSLSNEWSERVAMT:
        return getBscSlsNewServAmt();
      case BSCSLSNEXTSERVAMT:
        return getBscSlsNextServAmt();
      case BSCSLSEXISTSERVAMT:
        return getBscSlsExistServAmt();
      case BSCDISCOUNT:
        return getBscDiscount();
      case BSCTOTALSLSAMT:
        return getBscTotalSlsAmt();
      case DEFCNTTOTAL:
        return getDefCntTotal();
      case TARGETDISCOUNTAMT:
        return getTargetDiscountAmt();
      case GROUPNUMBER:
        return getGroupNumber();
      case GROUPLEADERFLAG:
        return getGroupLeaderFlag();
      case GROUPLEADERNAME:
        return getGroupLeaderName();
      case GROUPGRADE:
        return getGroupGrade();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case EMPLOYEENAME:
        return getEmployeeName();
      case JOBLANK:
        return getJobLank();
      case PRIRSLTVDNEWSERVAMT:
        return getPriRsltVdNewServAmt();
      case PRIRSLTVDNEXTSERVAMT:
        return getPriRsltVdNextServAmt();
      case PRIRSLTVDEXISTSERVAMT:
        return getPriRsltVdExistServAmt();
      case PRIRSLTNEWSERVAMT:
        return getPriRsltNewServAmt();
      case PRIRSLTNEXTSERVAMT:
        return getPriRsltNextServAmt();
      case PRIRSLTEXISTSERVAMT:
        return getPriRsltExistServAmt();
      case BSCSLSVDNEWSERVAMT:
        return getBscSlsVdNewServAmt();
      case BSCSLSVDNEXTSERVAMT:
        return getBscSlsVdNextServAmt();
      case BSCSLSVDEXISTSERVAMT:
        return getBscSlsVdExistServAmt();
      case BSCSLSNEWSERVAMT1:
        return getBscSlsNewServAmt1();
      case BSCSLSNEXTSERVAMT1:
        return getBscSlsNextServAmt1();
      case BSCSLSPRSNTOTALAMT:
        return getBscSlsPrsnTotalAmt();
      case TGTSALESVDNEWSERVAMT:
        return getTgtSalesVdNewServAmt();
      case TGTSALESVDNEXTSERVAMT:
        return getTgtSalesVdNextServAmt();
      case TGTSALESVDEXISTSERVAMT:
        return getTgtSalesVdExistServAmt();
      case TGTSALESNEWSERVAMT:
        return getTgtSalesNewServAmt();
      case TGTSALESNEXTSERVAMT:
        return getTgtSalesNextServAmt();
      case TGTSALESPRSNTOTALAMT:
        return getTgtSalesPrsnTotalAmt();
      case RSLTVDNEWSERVAMT:
        return getRsltVdNewServAmt();
      case RSLTVDEXISTSERVAMT:
        return getRsltVdExistServAmt();
      case RSLTVDTOTALAMT:
        return getRsltVdTotalAmt();
      case RSLTNEWSERVAMT:
        return getRsltNewServAmt();
      case RSLTNEXTSERVAMT:
        return getRsltNextServAmt();
      case RSLTPRSNTOTALAMT:
        return getRsltPrsnTotalAmt();
      case VISVDTOTALAMT:
        return getVisVdTotalAmt();
      case VISPRSNTOTALAMT:
        return getVisPrsnTotalAmt();
      case SLSPLNEFFECTIVEFLAG:
        return getSlsPlnEffectiveFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DATAKINDFLAG:
        setDataKindFlag((String)value);
        return;
      case BUSINESSYEAR:
        setBusinessYear((String)value);
        return;
      case YEARMONTH:
        setYearMonth((String)value);
        return;
      case SLSPRSNXSTSF:
        setSlsprsnXstsF((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case BSCSLSNEWSERVAMT:
        setBscSlsNewServAmt((String)value);
        return;
      case BSCSLSNEXTSERVAMT:
        setBscSlsNextServAmt((String)value);
        return;
      case BSCSLSEXISTSERVAMT:
        setBscSlsExistServAmt((String)value);
        return;
      case BSCDISCOUNT:
        setBscDiscount((String)value);
        return;
      case BSCTOTALSLSAMT:
        setBscTotalSlsAmt((String)value);
        return;
      case DEFCNTTOTAL:
        setDefCntTotal((String)value);
        return;
      case TARGETDISCOUNTAMT:
        setTargetDiscountAmt((String)value);
        return;
      case GROUPNUMBER:
        setGroupNumber((String)value);
        return;
      case GROUPLEADERFLAG:
        setGroupLeaderFlag((String)value);
        return;
      case GROUPLEADERNAME:
        setGroupLeaderName((String)value);
        return;
      case GROUPGRADE:
        setGroupGrade((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case EMPLOYEENAME:
        setEmployeeName((String)value);
        return;
      case JOBLANK:
        setJobLank((String)value);
        return;
      case PRIRSLTVDNEWSERVAMT:
        setPriRsltVdNewServAmt((String)value);
        return;
      case PRIRSLTVDNEXTSERVAMT:
        setPriRsltVdNextServAmt((String)value);
        return;
      case PRIRSLTVDEXISTSERVAMT:
        setPriRsltVdExistServAmt((String)value);
        return;
      case PRIRSLTNEWSERVAMT:
        setPriRsltNewServAmt((String)value);
        return;
      case PRIRSLTNEXTSERVAMT:
        setPriRsltNextServAmt((String)value);
        return;
      case PRIRSLTEXISTSERVAMT:
        setPriRsltExistServAmt((String)value);
        return;
      case BSCSLSVDNEWSERVAMT:
        setBscSlsVdNewServAmt((String)value);
        return;
      case BSCSLSVDNEXTSERVAMT:
        setBscSlsVdNextServAmt((String)value);
        return;
      case BSCSLSVDEXISTSERVAMT:
        setBscSlsVdExistServAmt((String)value);
        return;
      case BSCSLSNEWSERVAMT1:
        setBscSlsNewServAmt1((String)value);
        return;
      case BSCSLSNEXTSERVAMT1:
        setBscSlsNextServAmt1((String)value);
        return;
      case BSCSLSPRSNTOTALAMT:
        setBscSlsPrsnTotalAmt((String)value);
        return;
      case TGTSALESVDNEWSERVAMT:
        setTgtSalesVdNewServAmt((String)value);
        return;
      case TGTSALESVDNEXTSERVAMT:
        setTgtSalesVdNextServAmt((String)value);
        return;
      case TGTSALESVDEXISTSERVAMT:
        setTgtSalesVdExistServAmt((String)value);
        return;
      case TGTSALESNEWSERVAMT:
        setTgtSalesNewServAmt((String)value);
        return;
      case TGTSALESNEXTSERVAMT:
        setTgtSalesNextServAmt((String)value);
        return;
      case TGTSALESPRSNTOTALAMT:
        setTgtSalesPrsnTotalAmt((String)value);
        return;
      case RSLTVDNEWSERVAMT:
        setRsltVdNewServAmt((String)value);
        return;
      case RSLTVDEXISTSERVAMT:
        setRsltVdExistServAmt((String)value);
        return;
      case RSLTVDTOTALAMT:
        setRsltVdTotalAmt((String)value);
        return;
      case RSLTNEWSERVAMT:
        setRsltNewServAmt((String)value);
        return;
      case RSLTNEXTSERVAMT:
        setRsltNextServAmt((String)value);
        return;
      case RSLTPRSNTOTALAMT:
        setRsltPrsnTotalAmt((String)value);
        return;
      case VISVDTOTALAMT:
        setVisVdTotalAmt((String)value);
        return;
      case VISPRSNTOTALAMT:
        setVisPrsnTotalAmt((String)value);
        return;
      case SLSPLNEFFECTIVEFLAG:
        setSlsPlnEffectiveFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DataKindFlag
   */
  public String getDataKindFlag()
  {
    return (String)getAttributeInternal(DATAKINDFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DataKindFlag
   */
  public void setDataKindFlag(String value)
  {
    setAttributeInternal(DATAKINDFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BusinessYear
   */
  public String getBusinessYear()
  {
    return (String)getAttributeInternal(BUSINESSYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BusinessYear
   */
  public void setBusinessYear(String value)
  {
    setAttributeInternal(BUSINESSYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute YearMonth
   */
  public String getYearMonth()
  {
    return (String)getAttributeInternal(YEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute YearMonth
   */
  public void setYearMonth(String value)
  {
    setAttributeInternal(YEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SlsprsnXstsF
   */
  public String getSlsprsnXstsF()
  {
    return (String)getAttributeInternal(SLSPRSNXSTSF);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SlsprsnXstsF
   */
  public void setSlsprsnXstsF(String value)
  {
    setAttributeInternal(SLSPRSNXSTSF, value);
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
   * Gets the attribute value for the calculated attribute BscSlsNewServAmt
   */
  public String getBscSlsNewServAmt()
  {
    return (String)getAttributeInternal(BSCSLSNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsNewServAmt
   */
  public void setBscSlsNewServAmt(String value)
  {
    setAttributeInternal(BSCSLSNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsNextServAmt
   */
  public String getBscSlsNextServAmt()
  {
    return (String)getAttributeInternal(BSCSLSNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsNextServAmt
   */
  public void setBscSlsNextServAmt(String value)
  {
    setAttributeInternal(BSCSLSNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsExistServAmt
   */
  public String getBscSlsExistServAmt()
  {
    return (String)getAttributeInternal(BSCSLSEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsExistServAmt
   */
  public void setBscSlsExistServAmt(String value)
  {
    setAttributeInternal(BSCSLSEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscDiscount
   */
  public String getBscDiscount()
  {
    return (String)getAttributeInternal(BSCDISCOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscDiscount
   */
  public void setBscDiscount(String value)
  {
    setAttributeInternal(BSCDISCOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscTotalSlsAmt
   */
  public String getBscTotalSlsAmt()
  {
    return (String)getAttributeInternal(BSCTOTALSLSAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscTotalSlsAmt
   */
  public void setBscTotalSlsAmt(String value)
  {
    setAttributeInternal(BSCTOTALSLSAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DefCntTotal
   */
  public String getDefCntTotal()
  {
    return (String)getAttributeInternal(DEFCNTTOTAL);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DefCntTotal
   */
  public void setDefCntTotal(String value)
  {
    setAttributeInternal(DEFCNTTOTAL, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TargetDiscountAmt
   */
  public String getTargetDiscountAmt()
  {
    return (String)getAttributeInternal(TARGETDISCOUNTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TargetDiscountAmt
   */
  public void setTargetDiscountAmt(String value)
  {
    setAttributeInternal(TARGETDISCOUNTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute GroupNumber
   */
  public String getGroupNumber()
  {
    return (String)getAttributeInternal(GROUPNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute GroupNumber
   */
  public void setGroupNumber(String value)
  {
    setAttributeInternal(GROUPNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute GroupLeaderFlag
   */
  public String getGroupLeaderFlag()
  {
    return (String)getAttributeInternal(GROUPLEADERFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute GroupLeaderFlag
   */
  public void setGroupLeaderFlag(String value)
  {
    setAttributeInternal(GROUPLEADERFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute GroupLeaderName
   */
  public String getGroupLeaderName()
  {
    return (String)getAttributeInternal(GROUPLEADERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute GroupLeaderName
   */
  public void setGroupLeaderName(String value)
  {
    setAttributeInternal(GROUPLEADERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute GroupGrade
   */
  public String getGroupGrade()
  {
    return (String)getAttributeInternal(GROUPGRADE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute GroupGrade
   */
  public void setGroupGrade(String value)
  {
    setAttributeInternal(GROUPGRADE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeName
   */
  public String getEmployeeName()
  {
    return (String)getAttributeInternal(EMPLOYEENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeName
   */
  public void setEmployeeName(String value)
  {
    setAttributeInternal(EMPLOYEENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute JobLank
   */
  public String getJobLank()
  {
    return (String)getAttributeInternal(JOBLANK);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute JobLank
   */
  public void setJobLank(String value)
  {
    setAttributeInternal(JOBLANK, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltVdNewServAmt
   */
  public String getPriRsltVdNewServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTVDNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltVdNewServAmt
   */
  public void setPriRsltVdNewServAmt(String value)
  {
    setAttributeInternal(PRIRSLTVDNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltVdNextServAmt
   */
  public String getPriRsltVdNextServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTVDNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltVdNextServAmt
   */
  public void setPriRsltVdNextServAmt(String value)
  {
    setAttributeInternal(PRIRSLTVDNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltVdExistServAmt
   */
  public String getPriRsltVdExistServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTVDEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltVdExistServAmt
   */
  public void setPriRsltVdExistServAmt(String value)
  {
    setAttributeInternal(PRIRSLTVDEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltNewServAmt
   */
  public String getPriRsltNewServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltNewServAmt
   */
  public void setPriRsltNewServAmt(String value)
  {
    setAttributeInternal(PRIRSLTNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltNextServAmt
   */
  public String getPriRsltNextServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltNextServAmt
   */
  public void setPriRsltNextServAmt(String value)
  {
    setAttributeInternal(PRIRSLTNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PriRsltExistServAmt
   */
  public String getPriRsltExistServAmt()
  {
    return (String)getAttributeInternal(PRIRSLTEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PriRsltExistServAmt
   */
  public void setPriRsltExistServAmt(String value)
  {
    setAttributeInternal(PRIRSLTEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsVdNewServAmt
   */
  public String getBscSlsVdNewServAmt()
  {
    return (String)getAttributeInternal(BSCSLSVDNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsVdNewServAmt
   */
  public void setBscSlsVdNewServAmt(String value)
  {
    setAttributeInternal(BSCSLSVDNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsVdNextServAmt
   */
  public String getBscSlsVdNextServAmt()
  {
    return (String)getAttributeInternal(BSCSLSVDNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsVdNextServAmt
   */
  public void setBscSlsVdNextServAmt(String value)
  {
    setAttributeInternal(BSCSLSVDNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsVdExistServAmt
   */
  public String getBscSlsVdExistServAmt()
  {
    return (String)getAttributeInternal(BSCSLSVDEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsVdExistServAmt
   */
  public void setBscSlsVdExistServAmt(String value)
  {
    setAttributeInternal(BSCSLSVDEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsNewServAmt1
   */
  public String getBscSlsNewServAmt1()
  {
    return (String)getAttributeInternal(BSCSLSNEWSERVAMT1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsNewServAmt1
   */
  public void setBscSlsNewServAmt1(String value)
  {
    setAttributeInternal(BSCSLSNEWSERVAMT1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsNextServAmt1
   */
  public String getBscSlsNextServAmt1()
  {
    return (String)getAttributeInternal(BSCSLSNEXTSERVAMT1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsNextServAmt1
   */
  public void setBscSlsNextServAmt1(String value)
  {
    setAttributeInternal(BSCSLSNEXTSERVAMT1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BscSlsPrsnTotalAmt
   */
  public String getBscSlsPrsnTotalAmt()
  {
    return (String)getAttributeInternal(BSCSLSPRSNTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BscSlsPrsnTotalAmt
   */
  public void setBscSlsPrsnTotalAmt(String value)
  {
    setAttributeInternal(BSCSLSPRSNTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesVdNewServAmt
   */
  public String getTgtSalesVdNewServAmt()
  {
    return (String)getAttributeInternal(TGTSALESVDNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesVdNewServAmt
   */
  public void setTgtSalesVdNewServAmt(String value)
  {
    setAttributeInternal(TGTSALESVDNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesVdNextServAmt
   */
  public String getTgtSalesVdNextServAmt()
  {
    return (String)getAttributeInternal(TGTSALESVDNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesVdNextServAmt
   */
  public void setTgtSalesVdNextServAmt(String value)
  {
    setAttributeInternal(TGTSALESVDNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesVdExistServAmt
   */
  public String getTgtSalesVdExistServAmt()
  {
    return (String)getAttributeInternal(TGTSALESVDEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesVdExistServAmt
   */
  public void setTgtSalesVdExistServAmt(String value)
  {
    setAttributeInternal(TGTSALESVDEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesNewServAmt
   */
  public String getTgtSalesNewServAmt()
  {
    return (String)getAttributeInternal(TGTSALESNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesNewServAmt
   */
  public void setTgtSalesNewServAmt(String value)
  {
    setAttributeInternal(TGTSALESNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesNextServAmt
   */
  public String getTgtSalesNextServAmt()
  {
    return (String)getAttributeInternal(TGTSALESNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesNextServAmt
   */
  public void setTgtSalesNextServAmt(String value)
  {
    setAttributeInternal(TGTSALESNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TgtSalesPrsnTotalAmt
   */
  public String getTgtSalesPrsnTotalAmt()
  {
    return (String)getAttributeInternal(TGTSALESPRSNTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TgtSalesPrsnTotalAmt
   */
  public void setTgtSalesPrsnTotalAmt(String value)
  {
    setAttributeInternal(TGTSALESPRSNTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltVdNewServAmt
   */
  public String getRsltVdNewServAmt()
  {
    return (String)getAttributeInternal(RSLTVDNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltVdNewServAmt
   */
  public void setRsltVdNewServAmt(String value)
  {
    setAttributeInternal(RSLTVDNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltVdExistServAmt
   */
  public String getRsltVdExistServAmt()
  {
    return (String)getAttributeInternal(RSLTVDEXISTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltVdExistServAmt
   */
  public void setRsltVdExistServAmt(String value)
  {
    setAttributeInternal(RSLTVDEXISTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltVdTotalAmt
   */
  public String getRsltVdTotalAmt()
  {
    return (String)getAttributeInternal(RSLTVDTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltVdTotalAmt
   */
  public void setRsltVdTotalAmt(String value)
  {
    setAttributeInternal(RSLTVDTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltNewServAmt
   */
  public String getRsltNewServAmt()
  {
    return (String)getAttributeInternal(RSLTNEWSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltNewServAmt
   */
  public void setRsltNewServAmt(String value)
  {
    setAttributeInternal(RSLTNEWSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltNextServAmt
   */
  public String getRsltNextServAmt()
  {
    return (String)getAttributeInternal(RSLTNEXTSERVAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltNextServAmt
   */
  public void setRsltNextServAmt(String value)
  {
    setAttributeInternal(RSLTNEXTSERVAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RsltPrsnTotalAmt
   */
  public String getRsltPrsnTotalAmt()
  {
    return (String)getAttributeInternal(RSLTPRSNTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RsltPrsnTotalAmt
   */
  public void setRsltPrsnTotalAmt(String value)
  {
    setAttributeInternal(RSLTPRSNTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VisVdTotalAmt
   */
  public String getVisVdTotalAmt()
  {
    return (String)getAttributeInternal(VISVDTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VisVdTotalAmt
   */
  public void setVisVdTotalAmt(String value)
  {
    setAttributeInternal(VISVDTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute VisPrsnTotalAmt
   */
  public String getVisPrsnTotalAmt()
  {
    return (String)getAttributeInternal(VISPRSNTOTALAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute VisPrsnTotalAmt
   */
  public void setVisPrsnTotalAmt(String value)
  {
    setAttributeInternal(VISPRSNTOTALAMT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SlsPlnEffectiveFlag
   */
  public String getSlsPlnEffectiveFlag()
  {
    return (String)getAttributeInternal(SLSPLNEFFECTIVEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SlsPlnEffectiveFlag
   */
  public void setSlsPlnEffectiveFlag(String value)
  {
    setAttributeInternal(SLSPLNEFFECTIVEFLAG, value);
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



}