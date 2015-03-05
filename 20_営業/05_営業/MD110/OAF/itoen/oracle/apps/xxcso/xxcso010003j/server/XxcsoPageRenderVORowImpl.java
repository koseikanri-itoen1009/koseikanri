/*============================================================================
* ファイル名 : XxcsoPageRenderVORowImpl
* 概要説明   : ページ属性設定用ビュー行オブジェクトクラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-28 1.0  SCS柳平直人  新規作成
* 2012-06-12 1.1  SCSK桐生和幸 [E_本稼動_09602]契約取消ボタン追加対応
* 2015-02-02 1.2  SCSK山下翔太 [E_本稼動_12565]SP専決・契約書画面改修
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ページ属性設定用ビュー行オブジェクトクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPageRenderVORowImpl extends OAViewRowImpl 
{



  protected static final int DUMMY = 0;
  protected static final int BM1EXISTFLAG = 1;
  protected static final int BM2EXISTFLAG = 2;
  protected static final int BM3EXISTFLAG = 3;
  protected static final int BM1ENABLED = 4;
  protected static final int BM2ENABLED = 5;
  protected static final int BM3ENABLED = 6;
  protected static final int BM1DISABLED = 7;
  protected static final int BM2DISABLED = 8;
  protected static final int BM3DISABLED = 9;
  protected static final int INSTALLCODERENDER = 10;
  protected static final int REGIONVIEWRENDER = 11;
  protected static final int REGIONINPUTRENDER = 12;
  protected static final int APPLYBUTTONRENDER = 13;
  protected static final int SUBMITBUTTONRENDER = 14;
  protected static final int PRINTPDFBUTTONRENDER = 15;
  protected static final int PAYCONDINFODISABLED = 16;
  protected static final int PAYCONDINFOENABLED = 17;
  protected static final int OWNERCHANGEFLAG = 18;
  protected static final int OWNERCHANGERENDER = 19;
  protected static final int PAYCONDINFOVIEWRENDER = 20;
  protected static final int REJECTBUTTONRENDER = 21;
  protected static final int INSTSUPPEXISTFLAG = 22;
  protected static final int INTROCHGEXISTFLAG = 23;
  protected static final int ELECTRICEXISTFLAG = 24;
  protected static final int INSTSUPPENABLED = 25;
  protected static final int INTROCHGENABLED = 26;
  protected static final int ELECTRICENABLED = 27;
  protected static final int INSTSUPPDISABLED = 28;
  protected static final int INTROCHGDISABLED = 29;
  protected static final int ELECTRICDISABLED = 30;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPageRenderVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Dummy
   */
  public String getDummy()
  {
    return (String)getAttributeInternal(DUMMY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Dummy
   */
  public void setDummy(String value)
  {
    setAttributeInternal(DUMMY, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DUMMY:
        return getDummy();
      case BM1EXISTFLAG:
        return getBm1ExistFlag();
      case BM2EXISTFLAG:
        return getBm2ExistFlag();
      case BM3EXISTFLAG:
        return getBm3ExistFlag();
      case BM1ENABLED:
        return getBm1Enabled();
      case BM2ENABLED:
        return getBm2Enabled();
      case BM3ENABLED:
        return getBm3Enabled();
      case BM1DISABLED:
        return getBm1Disabled();
      case BM2DISABLED:
        return getBm2Disabled();
      case BM3DISABLED:
        return getBm3Disabled();
      case INSTALLCODERENDER:
        return getInstallCodeRender();
      case REGIONVIEWRENDER:
        return getRegionViewRender();
      case REGIONINPUTRENDER:
        return getRegionInputRender();
      case APPLYBUTTONRENDER:
        return getApplyButtonRender();
      case SUBMITBUTTONRENDER:
        return getSubmitButtonRender();
      case PRINTPDFBUTTONRENDER:
        return getPrintPdfButtonRender();
      case PAYCONDINFODISABLED:
        return getPayCondInfoDisabled();
      case PAYCONDINFOENABLED:
        return getPayCondInfoEnabled();
      case OWNERCHANGEFLAG:
        return getOwnerChangeFlag();
      case OWNERCHANGERENDER:
        return getOwnerChangeRender();
      case PAYCONDINFOVIEWRENDER:
        return getPayCondInfoViewRender();
      case REJECTBUTTONRENDER:
        return getRejectButtonRender();
      case INSTSUPPEXISTFLAG:
        return getInstSuppExistFlag();
      case INTROCHGEXISTFLAG:
        return getIntroChgExistFlag();
      case ELECTRICEXISTFLAG:
        return getElectricExistFlag();
      case INSTSUPPENABLED:
        return getInstSuppEnabled();
      case INTROCHGENABLED:
        return getIntroChgEnabled();
      case ELECTRICENABLED:
        return getElectricEnabled();
      case INSTSUPPDISABLED:
        return getInstSuppDisabled();
      case INTROCHGDISABLED:
        return getIntroChgDisabled();
      case ELECTRICDISABLED:
        return getElectricDisabled();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DUMMY:
        setDummy((String)value);
        return;
      case BM1EXISTFLAG:
        setBm1ExistFlag((String)value);
        return;
      case BM2EXISTFLAG:
        setBm2ExistFlag((String)value);
        return;
      case BM3EXISTFLAG:
        setBm3ExistFlag((String)value);
        return;
      case BM1ENABLED:
        setBm1Enabled((Boolean)value);
        return;
      case BM2ENABLED:
        setBm2Enabled((Boolean)value);
        return;
      case BM3ENABLED:
        setBm3Enabled((Boolean)value);
        return;
      case BM1DISABLED:
        setBm1Disabled((Boolean)value);
        return;
      case BM2DISABLED:
        setBm2Disabled((Boolean)value);
        return;
      case BM3DISABLED:
        setBm3Disabled((Boolean)value);
        return;
      case INSTALLCODERENDER:
        setInstallCodeRender((Boolean)value);
        return;
      case REGIONVIEWRENDER:
        setRegionViewRender((Boolean)value);
        return;
      case REGIONINPUTRENDER:
        setRegionInputRender((Boolean)value);
        return;
      case APPLYBUTTONRENDER:
        setApplyButtonRender((Boolean)value);
        return;
      case SUBMITBUTTONRENDER:
        setSubmitButtonRender((Boolean)value);
        return;
      case PRINTPDFBUTTONRENDER:
        setPrintPdfButtonRender((Boolean)value);
        return;
      case PAYCONDINFODISABLED:
        setPayCondInfoDisabled((Boolean)value);
        return;
      case PAYCONDINFOENABLED:
        setPayCondInfoEnabled((Boolean)value);
        return;
      case OWNERCHANGEFLAG:
        setOwnerChangeFlag((String)value);
        return;
      case OWNERCHANGERENDER:
        setOwnerChangeRender((Boolean)value);
        return;
      case PAYCONDINFOVIEWRENDER:
        setPayCondInfoViewRender((Boolean)value);
        return;
      case REJECTBUTTONRENDER:
        setRejectButtonRender((Boolean)value);
        return;
      case INSTSUPPEXISTFLAG:
        setInstSuppExistFlag((String)value);
        return;
      case INTROCHGEXISTFLAG:
        setIntroChgExistFlag((String)value);
        return;
      case ELECTRICEXISTFLAG:
        setElectricExistFlag((String)value);
        return;
      case INSTSUPPENABLED:
        setInstSuppEnabled((Boolean)value);
        return;
      case INTROCHGENABLED:
        setIntroChgEnabled((Boolean)value);
        return;
      case ELECTRICENABLED:
        setElectricEnabled((Boolean)value);
        return;
      case INSTSUPPDISABLED:
        setInstSuppDisabled((Boolean)value);
        return;
      case INTROCHGDISABLED:
        setIntroChgDisabled((Boolean)value);
        return;
      case ELECTRICDISABLED:
        setElectricDisabled((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1ExistFlag
   */
  public String getBm1ExistFlag()
  {
    return (String)getAttributeInternal(BM1EXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1ExistFlag
   */
  public void setBm1ExistFlag(String value)
  {
    setAttributeInternal(BM1EXISTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2ExistFlag
   */
  public String getBm2ExistFlag()
  {
    return (String)getAttributeInternal(BM2EXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2ExistFlag
   */
  public void setBm2ExistFlag(String value)
  {
    setAttributeInternal(BM2EXISTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3ExistFlag
   */
  public String getBm3ExistFlag()
  {
    return (String)getAttributeInternal(BM3EXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3ExistFlag
   */
  public void setBm3ExistFlag(String value)
  {
    setAttributeInternal(BM3EXISTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Enabled
   */
  public Boolean getBm1Enabled()
  {
    return (Boolean)getAttributeInternal(BM1ENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Enabled
   */
  public void setBm1Enabled(Boolean value)
  {
    setAttributeInternal(BM1ENABLED, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Enabled
   */
  public Boolean getBm3Enabled()
  {
    return (Boolean)getAttributeInternal(BM3ENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Enabled
   */
  public void setBm3Enabled(Boolean value)
  {
    setAttributeInternal(BM3ENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm1Disabled
   */
  public Boolean getBm1Disabled()
  {
    return (Boolean)getAttributeInternal(BM1DISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm1Disabled
   */
  public void setBm1Disabled(Boolean value)
  {
    setAttributeInternal(BM1DISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Disabled
   */
  public Boolean getBm2Disabled()
  {
    return (Boolean)getAttributeInternal(BM2DISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Disabled
   */
  public void setBm2Disabled(Boolean value)
  {
    setAttributeInternal(BM2DISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm3Disabled
   */
  public Boolean getBm3Disabled()
  {
    return (Boolean)getAttributeInternal(BM3DISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm3Disabled
   */
  public void setBm3Disabled(Boolean value)
  {
    setAttributeInternal(BM3DISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Bm2Enabled
   */
  public Boolean getBm2Enabled()
  {
    return (Boolean)getAttributeInternal(BM2ENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Bm2Enabled
   */
  public void setBm2Enabled(Boolean value)
  {
    setAttributeInternal(BM2ENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstallCodeRender
   */
  public Boolean getInstallCodeRender()
  {
    return (Boolean)getAttributeInternal(INSTALLCODERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstallCodeRender
   */
  public void setInstallCodeRender(Boolean value)
  {
    setAttributeInternal(INSTALLCODERENDER, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ApplyButtonRender
   */
  public Boolean getApplyButtonRender()
  {
    return (Boolean)getAttributeInternal(APPLYBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplyButtonRender
   */
  public void setApplyButtonRender(Boolean value)
  {
    setAttributeInternal(APPLYBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SubmitButtonRender
   */
  public Boolean getSubmitButtonRender()
  {
    return (Boolean)getAttributeInternal(SUBMITBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SubmitButtonRender
   */
  public void setSubmitButtonRender(Boolean value)
  {
    setAttributeInternal(SUBMITBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PrintPdfButtonRender
   */
  public Boolean getPrintPdfButtonRender()
  {
    return (Boolean)getAttributeInternal(PRINTPDFBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PrintPdfButtonRender
   */
  public void setPrintPdfButtonRender(Boolean value)
  {
    setAttributeInternal(PRINTPDFBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RegionViewRender
   */
  public Boolean getRegionViewRender()
  {
    return (Boolean)getAttributeInternal(REGIONVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RegionViewRender
   */
  public void setRegionViewRender(Boolean value)
  {
    setAttributeInternal(REGIONVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RegionInputRender
   */
  public Boolean getRegionInputRender()
  {
    return (Boolean)getAttributeInternal(REGIONINPUTRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RegionInputRender
   */
  public void setRegionInputRender(Boolean value)
  {
    setAttributeInternal(REGIONINPUTRENDER, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute PayCondInfoDisabled
   */
  public Boolean getPayCondInfoDisabled()
  {
    return (Boolean)getAttributeInternal(PAYCONDINFODISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PayCondInfoDisabled
   */
  public void setPayCondInfoDisabled(Boolean value)
  {
    setAttributeInternal(PAYCONDINFODISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PayCondInfoEnabled
   */
  public Boolean getPayCondInfoEnabled()
  {
    return (Boolean)getAttributeInternal(PAYCONDINFOENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PayCondInfoEnabled
   */
  public void setPayCondInfoEnabled(Boolean value)
  {
    setAttributeInternal(PAYCONDINFOENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OwnerChangeFlag
   */
  public String getOwnerChangeFlag()
  {
    return (String)getAttributeInternal(OWNERCHANGEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OwnerChangeFlag
   */
  public void setOwnerChangeFlag(String value)
  {
    setAttributeInternal(OWNERCHANGEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OwnerChangeRender
   */
  public Boolean getOwnerChangeRender()
  {
    return (Boolean)getAttributeInternal(OWNERCHANGERENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OwnerChangeRender
   */
  public void setOwnerChangeRender(Boolean value)
  {
    setAttributeInternal(OWNERCHANGERENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PayCondInfoViewRender
   */
  public Boolean getPayCondInfoViewRender()
  {
    return (Boolean)getAttributeInternal(PAYCONDINFOVIEWRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PayCondInfoViewRender
   */
  public void setPayCondInfoViewRender(Boolean value)
  {
    setAttributeInternal(PAYCONDINFOVIEWRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RejectButtonRender
   */
  public Boolean getRejectButtonRender()
  {
    return (Boolean)getAttributeInternal(REJECTBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RejectButtonRender
   */
  public void setRejectButtonRender(Boolean value)
  {
    setAttributeInternal(REJECTBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstSuppExistFlag
   */
  public String getInstSuppExistFlag()
  {
    return (String)getAttributeInternal(INSTSUPPEXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstSuppExistFlag
   */
  public void setInstSuppExistFlag(String value)
  {
    setAttributeInternal(INSTSUPPEXISTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgExistFlag
   */
  public String getIntroChgExistFlag()
  {
    return (String)getAttributeInternal(INTROCHGEXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgExistFlag
   */
  public void setIntroChgExistFlag(String value)
  {
    setAttributeInternal(INTROCHGEXISTFLAG, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute InstSuppEnabled
   */
  public Boolean getInstSuppEnabled()
  {
    return (Boolean)getAttributeInternal(INSTSUPPENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstSuppEnabled
   */
  public void setInstSuppEnabled(Boolean value)
  {
    setAttributeInternal(INSTSUPPENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgEnabled
   */
  public Boolean getIntroChgEnabled()
  {
    return (Boolean)getAttributeInternal(INTROCHGENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgEnabled
   */
  public void setIntroChgEnabled(Boolean value)
  {
    setAttributeInternal(INTROCHGENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricEnabled
   */
  public Boolean getElectricEnabled()
  {
    return (Boolean)getAttributeInternal(ELECTRICENABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricEnabled
   */
  public void setElectricEnabled(Boolean value)
  {
    setAttributeInternal(ELECTRICENABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute InstSuppDisabled
   */
  public Boolean getInstSuppDisabled()
  {
    return (Boolean)getAttributeInternal(INSTSUPPDISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute InstSuppDisabled
   */
  public void setInstSuppDisabled(Boolean value)
  {
    setAttributeInternal(INSTSUPPDISABLED, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricDisabled
   */
  public Boolean getElectricDisabled()
  {
    return (Boolean)getAttributeInternal(ELECTRICDISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricDisabled
   */
  public void setElectricDisabled(Boolean value)
  {
    setAttributeInternal(ELECTRICDISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IntroChgDisabled
   */
  public Boolean getIntroChgDisabled()
  {
    return (Boolean)getAttributeInternal(INTROCHGDISABLED);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IntroChgDisabled
   */
  public void setIntroChgDisabled(Boolean value)
  {
    setAttributeInternal(INTROCHGDISABLED, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ElectricExistFlag
   */
  public String getElectricExistFlag()
  {
    return (String)getAttributeInternal(ELECTRICEXISTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ElectricExistFlag
   */
  public void setElectricExistFlag(String value)
  {
    setAttributeInternal(ELECTRICEXISTFLAG, value);
  }













}